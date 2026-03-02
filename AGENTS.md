# Repository Guidelines

## Project Structure & Module Organization
This repo is a Python/Jupyter demo for NICAR 2026 focused on reusable AI skills.
- `fec_find_filings.py`: CLI to query OpenFEC filings by committee ID.
- `set_jupyter_kernel.py`: one-time local Jupyter kernel setup for this repo.
- `01_quickstart_tutorials.md`: attendee quickstart commands and first-run workflows.
- `02_skills_learning_notes.md`: session notes, exercises, and troubleshooting.
- `03_build_a_skill_from_your_code.md`: tutorial for turning existing R/Python scripts into a skill.
- `04_state_county_rankings_skill_example.md`: concrete state county rankings skill example.
- `05_majority_minority_change_skill_example.md`: concrete majority-minority change skill example.
- `analysis/`: notebook work area; keep reusable templates in `analysis/notebook_templates/`.
- `data/`: project data buckets (`source/`, `processed/`, `public/`, `documentation/`, `html_reports/`).
- `skills/`: canonical session copy of all skills for conference content.
- `.claude/skills/`: active skills for Claude Code.
- `.codex/skills/`: active skills for Codex CLI.

## Build, Test, and Development Commands
- `uv sync`: install/update dependencies from `pyproject.toml` and `uv.lock`.
- `uv run python fec_find_filings.py --help`: inspect CLI options.
- `uv run python fec_find_filings.py C00770941 --limit 5`: quick API smoke run.
- `uv run jupyter lab`: start local notebooks in the project environment.
- `quarto render`: build reports configured in `_quarto.yml` to `data/html_reports/`.
- `uv run python set_jupyter_kernel.py`: configure the project kernel (run intentionally; it performs setup actions).
- `CODEX_HOME=/path/to/repo/.codex codex`: launch Codex with repo-local active skills.
- `uv run skills/fecfile/scripts/fetch_filing.py 1896830 --summary-only`: smoke test the FEC skill script from repo root.
- `Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R --input skills/state-county-rankings/data/county_demographics_acs5_2023.csv --state GA --top-n 5`: smoke test a bundled R skill script.

## Coding Style & Naming Conventions
- Target Python `>=3.12` (see `pyproject.toml`), 4-space indentation, PEP 8 naming.
- Use `snake_case` for functions/variables and descriptive CLI flags.
- Prefer small, composable scripts with explicit `argparse` options and clear help text.
- Keep paths repo-relative and avoid hard-coded user-specific directories.
- For top-level tutorial docs, use numeric ordering prefixes (for example: `01_...`, `02_...`) so reading order is explicit.

## Testing Guidelines
No formal `tests/` suite is present yet. Use script-level validation:
- Run `uv run python fec_find_filings.py ...` with small limits (`--limit 1` or `5`).
- Validate output modes you touch (`table`, `json`, `ndjson`, `csv`).
- For notebook/report changes, run `quarto render` and confirm output in `data/html_reports/`.
- For skill changes, verify mirrored updates in both `.claude/skills/` and `.codex/skills/` and run the touched script (`uv run ...` for Python skills, `Rscript ...` for R skills).
- For `weather-forecast`, ensure `--json` output is machine-parseable JSON with no non-JSON preamble.
- For `skill-creator` packaging changes, ensure zip outputs exclude transient files like `__pycache__/` and `*.pyc`.

## Recent Skill Updates (March 2026)
- Prefer repo-root script paths in docs and examples (for example, `skills/<skill-name>/scripts/...`) so commands are copy/paste-safe without changing directories.
- `skills/weather-forecast/scripts/get_forecast.py` now emits clean JSON on stdout for `--json`; status/error text goes to stderr or table mode only.
- `skills/weather-forecast/scripts/get_coordinates.py` now exits immediately on invalid state input with a single clear error.
- `skills/skill-creator/scripts/package_skill.py` now filters transient files (`__pycache__/`, `.pyc`, `.pyo`, `.DS_Store`, `.git`) from packaged zips.

## Commit & Pull Request Guidelines
- Recent history uses short, direct subjects (for example: `tweak readme`, `migrate over skills files`).
- Keep commit messages imperative and scoped to one change.
- PRs should include: purpose, key files changed, commands run for verification, and any API/data assumptions.
- Link related issues/tasks and include rendered output screenshots only when UI/report layout changes.
- If a skill changes, note which directories were updated (`skills/`, `.claude/skills/`, `.codex/skills/`) and why.

## Security & Configuration Tips
- Set `FEC_API_KEY` or `DATA_GOV_API_KEY` in local environment only; never commit secrets.
- For `tidycensus` workflows, set `CENSUS_API_KEY` locally and never commit it.
- `.env`, `.venv`, and generated notebooks are ignored; keep large/raw data in the existing `data/` subfolders.


## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.
### Available skills
- fecfile: Analyze FEC (Federal Election Commission) campaign finance filings. Use when working with FEC filing IDs, campaign finance data, contributions, disbursements, or political committee financial reports. (file: /Users/akessler/GITREPOS/github_kessler/nicar2026_skills_in_codex_claude/.codex/skills/fecfile/SKILL.md)
- image-rotator: This skill should be used when users need to rotate images by 90 degrees. It handles image rotation tasks for common formats (PNG, JPG, JPEG, GIF, BMP, TIFF) using a reliable Python script that preserves image quality and supports both clockwise and counter-clockwise rotation. (file: /Users/akessler/GITREPOS/github_kessler/nicar2026_skills_in_codex_claude/.codex/skills/image-rotator/SKILL.md)
- majority-minority-change: This skill should be used when users need to analyze county-level racial composition change between two Census snapshots and identify where places crossed a majority-minority threshold. (file: /Users/akessler/GITREPOS/github_kessler/nicar2026_skills_in_codex_claude/.codex/skills/majority-minority-change/SKILL.md)
- skill-creator: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. (file: /Users/akessler/GITREPOS/github_kessler/nicar2026_skills_in_codex_claude/.codex/skills/skill-creator/SKILL.md)
- state-county-rankings: This skill should be used when users need ranked county-level demographic metrics within a state from a local CSV file, such as income, population, poverty, or rent. (file: /Users/akessler/GITREPOS/github_kessler/nicar2026_skills_in_codex_claude/.codex/skills/state-county-rankings/SKILL.md)
- weather-forecast: Fetch 7-day weather forecasts from Open-Meteo API. ALWAYS use get_coordinates.py first when given city names to look up coordinates, then use get_forecast.py with those coordinates. Use for weather forecasts, weather data, or temperature trends. (file: /Users/akessler/GITREPOS/github_kessler/nicar2026_skills_in_codex_claude/.codex/skills/weather-forecast/SKILL.md)
### How to use skills
- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.
- How to use a skill (progressive disclosure):
  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.
  2) When `SKILL.md` references relative paths (e.g., `scripts/foo.py`), resolve them relative to the skill directory listed above first, and only consider other paths if needed.
  3) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.
  4) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.
  5) If `assets/` or templates exist, reuse them instead of recreating from scratch.
- Coordination and sequencing:
  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.
  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.
- Context hygiene:
  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.
  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.
  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.
- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.
