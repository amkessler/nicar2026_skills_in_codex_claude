# test_agentskills_fec

This repo helps demostrate the `fecfile` agent skill at `.codex/skills/fecfile` so collaborators can use it without a separate install. To enable repo-local skills, set `CODEX_HOME` to the repo root’s `.codex` directory or symlink the skill into `~/.codex/skills`.

The `fecfile` skill analyzes Federal Election Commission (FEC) campaign finance filings. It can fetch filing summaries, parse itemized contributions and disbursements, and produce quick analyses (top spenders, contributions by state, vendor totals, etc.).

Dependencies and installation
- Fecfile skill runtime: `uv` + Python 3.9+ and internet access (dependencies are installed automatically by `uv run`)
- Codex CLI install: `npm i -g @openai/codex` (or Homebrew; see https://developers.openai.com/codex/cli)
- Codex CLI first run: `codex`, then sign in with your ChatGPT account or an API key (see https://developers.openai.com/codex/auth)

Fecfile capabilities checklist:
- Fetch filing data by filing ID: full filing, summary-only, or selected schedules
- Report F3/F3P/F3X summary metrics (receipts, disbursements, cash on hand, debts, totals)
- Detect amendments and original filings (`amendment_indicator`, `previous_report_amendment_indicator`)
- Read coverage periods and compute days covered
- Analyze Schedules A–E (contributions, disbursements, loans, debts, independent expenditures)
- Pre-filter large filings by schedule selection
- Post-filter/aggregate with pandas
- Stream massive filings for constant-memory aggregation
- External guidance for finding filing IDs via FEC website or FEC API

Example prompts:
- "Analyze filing ID 1896830."
- "Show the summary-only view for filing 1896830."
- "What are the largest expenditures in filing 1896830?"
- "Show a table of contribution counts and totals by state for filing 1896830."
- "Pull Schedule A and list the top 10 contributions."
- "Summarize Schedule B spending by purpose."

If you prefer a global install, copy `.codex/skills/fecfile` into `~/.codex/skills/` on your machine.

Helper script: find filings by committee ID
- Script: `fec_find_filings.py`
- Uses the OpenFEC API to list filing IDs for a committee (the `file_number` field)
- API key: set `FEC_API_KEY` or `DATA_GOV_API_KEY`, or pass `--api-key` (defaults to DEMO_KEY)
- `committee_name` is included by default (it’s part of the standard field set)

Examples:
```bash
uv run fec_find_filings.py C00770941 --limit 5
uv run fec_find_filings.py C00770941 --form-type F3X --report-year 2024
uv run fec_find_filings.py C00770941 --format csv --limit 10
uv run fec_find_filings.py C00770941 --fields committee_name,file_number,form_type,receipt_date
```
