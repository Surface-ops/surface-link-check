#!/usr/bin/env bash
# Surface Link Check: extract URLs from files and preflight each via Surface.
set -uo pipefail
shopt -s globstar nullglob
ENDPOINT="${SURFACE_ENDPOINT:-https://nova-otter-delta-cloud.grok.me}"
FAIL_ON=",${SURFACE_FAIL_ON:-skip,dead,blocked},"
MAX="${SURFACE_MAX:-200}"
files=()
for g in ${SURFACE_FILES:-**/*.md}; do for f in $g; do [[ -f "$f" && "$f" != node_modules/* ]] && files+=("$f"); done; done
if [ ${#files[@]} -eq 0 ]; then echo "No files matched."; echo "checked=0" >> "${GITHUB_OUTPUT:-/dev/null}"; echo "failed=0" >> "${GITHUB_OUTPUT:-/dev/null}"; exit 0; fi
mapfile -t urls < <(grep -ohE 'https?://[^][()<>"'"'"' `]+' "${files[@]}" | sed -E 's/[.,;:!?*_]+$//' | grep -vE '://(localhost|127\.|0\.0\.0\.0|example\.(com|org))' | sort -u | head -n "$MAX")
checked=0; failed=0; report=""
hdr=(-H "content-type: application/json" -H "user-agent: surface-link-check/1.0")
[ -n "${SURFACE_KEY:-}" ] && hdr+=(-H "authorization: Bearer ${SURFACE_KEY}")
[ -n "${SURFACE_EXTRA_HEADER:-}" ] && hdr+=(-H "${SURFACE_EXTRA_HEADER}")
for u in "${urls[@]}"; do
  body=$(jq -nc --arg u "$u" '{url:$u}')
  r=$(curl -s -m 30 -X POST "$ENDPOINT/v1/preflight" "${hdr[@]}" -d "$body")
  v=$(jq -r '.verdict // "error"' <<<"$r" 2>/dev/null || echo error)
  why=$(jq -r '.reason // .error // "no response"' <<<"$r" 2>/dev/null || echo "bad response")
  st=$(jq -r '.status // "-"' <<<"$r" 2>/dev/null || echo -)
  checked=$((checked+1))
  mark="ok"
  if [[ "$FAIL_ON" == *",$v,"* ]]; then failed=$((failed+1)); mark="FAIL"; echo "::warning title=Surface link check::$u -> $v ($why)"; fi
  printf '%-4s %-8s %-4s %s  (%s)\n' "$mark" "$v" "$st" "$u" "$why"
  report+="| $mark | \`$v\` | $st | $u | $why |"$'\n'
done
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  { echo "### Surface Link Check"; echo "$checked links checked, $failed failing"; echo; echo "| | verdict | status | url | reason |"; echo "|---|---|---|---|---|"; printf '%s' "$report"; } >> "$GITHUB_STEP_SUMMARY"
fi
echo "checked=$checked" >> "${GITHUB_OUTPUT:-/dev/null}"; echo "failed=$failed" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "Checked $checked links, $failed failing."
[ "$failed" -eq 0 ]
