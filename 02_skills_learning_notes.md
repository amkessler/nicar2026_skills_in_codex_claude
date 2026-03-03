# Skills Session Notes

This guide is an attendee-friendly companion to `01_quickstart_underlying_code.md`.
Use it in session to explain how skills work, when to use each one, and how to avoid common mistakes.

## 1) Skill Mental Model

A skill is a reusable instruction package for the assistant.
It helps the assistant choose better steps and use stable scripts instead of improvising every time.

Each skill usually has:
- `SKILL.md`: purpose, trigger description, workflow rules
- `scripts/`: executable helpers for deterministic tasks
- `references/`: source docs for fields, schemas, and policies
- `assets/`: templates or files used in outputs

How triggering works:
- Auto-trigger: assistant uses `description` in `SKILL.md` to decide relevance
- Manual trigger: `/skill-name` (Claude) or `$skill-name` (Codex)

Practical rule:
- Use scripts for repeatable computation.
- Use AI reasoning for interpretation and narrative around script results.

## 2) Which Skill Should I Use?

| If an attendee says... | Skill | First action |
|---|---|---|
| "Analyze filing 1896830" | `fecfile` | Run summary-only first |
| "What is the weather in Denver this week?" | `weather-forecast` | Resolve coordinates, then forecast |
| "Rotate this image 90 degrees" | `image-rotator` | Run rotate script with default args |
| "Help me build a new skill for city budgets" | `skill-creator` | Run `init_skill.py` scaffold |
| "Rank counties in Ohio by poverty rate" | `state-county-rankings` | Run rankings script on local CSV with metric list |
| "Which counties crossed majority-minority thresholds?" | `majority-minority-change` | Compare start/end files and compute crossings |

## 3) Starter Prompts Attendees Can Copy

### FEC
- "Analyze filing `1896830` and give me 3 key numbers."
- "For filing `1896830`, show top contributors from Schedule A."
- "For filing `1896830`, summarize Schedule B spending by purpose."

### Weather
- "Get a 7-day forecast for Philadelphia, PA and show a table."
- "Get JSON forecast output for Denver, CO so I can chart it."

### Image Rotation
- "Rotate `headshot.jpg` 90 degrees clockwise."
- "Rotate `scan.png` counter-clockwise and save as `scan_fixed.png`."

### Skill Creation
- "Create a new skill called `city-budget` under `skills/`."
- "Validate and package `skills/city-budget` into `dist/`."

### State County Rankings
- "Rank Ohio counties by median household income and poverty rate."
- "Show the top 15 North Carolina counties by median gross rent."
- "Give me the bottom 10 California counties by total population."

### Majority-Minority Change
- "Compare 2010 vs 2020 county files and find majority-minority crossings."
- "Which Georgia counties crossed into majority-minority status?"
- "Show largest non-white share increases in Texas counties."

## 4) Prompt Quality: Bad vs Good

Bad:
- "Look at this filing."

Good:
- "Analyze filing `1896830`. Start with summary-only. Then show top 10 Schedule A contributors as a table with name, state, amount, date."

Bad:
- "Get weather for Denver."

Good:
- "Use the weather skill workflow: resolve coordinates for Denver, CO, fetch 7-day forecast, and return both table and JSON."

Why this matters:
- Better prompts specify input, workflow, output format, and limits.

## 5) What Success Looks Like

### FEC
- You can identify a filing ID from `fec_find_filings.py`.
- You run summary-only before pulling full schedules.
- Output includes clear totals or ranked tables, not raw dumps.

### Weather
- You see two numbers from coordinate lookup (lat/lon).
- Forecast command returns 7-day table or JSON payload.

### Skill Creation
- New directory contains `SKILL.md` plus resource folders.
- `quick_validate.py` returns `Skill is valid!`.
- `package_skill.py` produces `dist/<skill-name>.zip`.

## 6) Troubleshooting Matrix

| Problem | Likely cause | Fix |
|---|---|---|
| `uv: command not found` | uv not installed | Install uv and rerun `uv sync` |
| FEC request fails or rate-limits | Missing API key | Set `FEC_API_KEY` or `DATA_GOV_API_KEY` |
| FEC output too large | Pulled full filing too early | Use `--summary-only`, then `--schedule`, then `--stream` |
| City not found by coordinates script | Only top 1000 US cities in local DB | Use direct lat/lon with forecast script |
| Image rotate fails with Pillow error | Dependencies not installed | Run `uv sync` |
| Ranking/change scripts fail on columns | Input file schema mismatch | Check required columns in each skill `references/` doc |
| Skill validation fails | Missing/invalid frontmatter | Fix `name` and `description` in `SKILL.md` |

## 7) Mini Exercises 

### Exercise A: FEC Basics
1. Find 5 filings for a committee using `fec_find_filings.py`.
2. Choose one filing ID.
3. Run summary-only and write down 3 key numbers.
4. Pull one schedule and report top 5 rows by amount.

### Exercise B: Weather Flow
1. Get coordinates for one city.
2. Pull forecast table.
3. Pull JSON and identify hottest and coldest periods.

### Exercise C: Majority-Minority Change
1. Run `skills/majority-minority-change/scripts/analyze_majority_minority_change.R` on the bundled 2010 and 2020 county files.
2. Re-run with `--state "Georgia"` (or another state) to compare state-specific results.
3. Count counties where `crossed_to_majority_minority == TRUE`.
4. Write one headline and one methodology caveat from the output.

## 8) Safety and Scale Checklist

For first-time attendees, enforce this checklist:
- Always run summary/overview before full data pulls.
- Limit or aggregate outputs before sharing.
- Prefer script outputs over hand-typed field names.
- Verify field names from reference docs.
- Keep raw data out of chat when it is large; summarize instead.

## 9) How to Inspect a Skill Before Using It

1. Open `SKILL.md`.
2. Read required order of operations.
3. Identify referenced scripts and docs.
4. Run scripts exactly as documented.
5. Only then ask for interpretation or narrative.

## 10) Common First-Time Attendee Misconceptions

- "A skill is a plugin."
  - Not exactly. It is instructions plus optional local resources.
- "If a skill exists, it will always trigger."
  - No. Trigger depends on the request and skill description.
- "The assistant should just know field names."
  - Risky. Always verify from references or script output.
- "Bigger output is better output."
  - Usually false. Curated, bounded output is better for analysis.
