# Surface Link Check

A GitHub Action that checks every link in your Markdown on each push and PR, using [Surface](https://nova-otter-delta-cloud.grok.me) URL preflight. Surface follows redirects and shorteners, then gives each link a verdict: fetch, skip, dead, or blocked. That way broken docs links get caught before readers or AI agents run into them.

- No setup: works without a key, and the first 1M checks each month are free.
- Writes a table to the job summary and adds a warning annotation for each failing link.
- No dependencies beyond `bash`, `curl` and `jq`, which every GitHub runner already has.

## Usage

```yaml
# .github/workflows/links.yml
name: links
on:
  push:
  pull_request:
  schedule:
    - cron: "0 6 * * 1"   # weekly, to catch link rot
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Surface-ops/surface-link-check@v1
        with:
          files: "**/*.md"
```

## Inputs

| input | default | description |
|---|---|---|
| `files` | `**/*.md` | Space-separated globs to scan |
| `fail-on` | `skip,dead,blocked` | Verdicts that fail the job |
| `max-links` | `200` | Maximum unique links checked per run |
| `api-key` | none | Optional Surface key, for usage above the free tier |
| `endpoint` | Surface API | Override the API base URL |

## Outputs

`checked` and `failed` (counts).

## Pricing

The first 1M checks each month are free, then $0.25 per 1k. See [pricing](https://nova-otter-delta-cloud.grok.me).

## Also available

The same check is available to agents over MCP (`preflight_url`) at `https://nova-otter-delta-cloud.grok.me/mcp`, or over REST at `POST /v1/preflight`.

MIT licensed.
