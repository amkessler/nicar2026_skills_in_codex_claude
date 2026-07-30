# Repository Guidelines

## Project Structure & Module Organization
This repo is a Python/Jupyter demo for NICAR 2026 focused on reusable AI skills.
- `fec_find_filings.py`: CLI to query OpenFEC filings by committee ID.
- `set_jupyter_kernel.py`: one-time local Jupyter kernel setup for this repo.
- `01_quickstart_underlying_code.md`: attendee quickstart commands and first-run workflows.
- `02_skills_learning_notes.md`: session notes, exercises, and troubleshooting.
- `03_fecfile_examples.md`: worked FEC filing prompts and examples.
- `04_build_a_skill_from_your_code.md`: tutorial for turning existing R/Python scripts into a skill.
- `05_skill_build_example_state_county_rankings.md`: concrete state county rankings skill example.
- `06_skill_build_example_majority_minority_change.md`: concrete majority-minority change skill example.
- `analysis/`: notebook work area; keep reusable templates in `analysis/notebook_templates/`.
- `data/`: project data buckets (`source/`, `processed/`, `public/`, `documentation/`, `html_reports/`).
- `skills/`: canonical session copy of all skills for conference content.
- `.claude/skills/`: active skills for Claude Code.
- `.agents/skills/`: active repo-local skills for Codex CLI.

## Build, Test, and Development Commands
- `uv sync`: install/update dependencies from `pyproject.toml` and `uv.lock`.
- `uv run python fec_find_filings.py --help`: inspect CLI options.
- `uv run python fec_find_filings.py C00770941 --limit 5`: quick API smoke run.
- `uv run jupyter lab`: start local notebooks in the project environment.
- `quarto render`: build reports configured in `_quarto.yml` to `data/html_reports/`.
- `uv run python set_jupyter_kernel.py`: configure the project kernel (run intentionally; it performs setup actions).
- `codex`: launch Codex from the repo root; Codex discovers repo-local skills from `.agents/skills/`.
- `uv run --script skills/fecfile/scripts/fetch_filing.py 1896830 --summary-only`: smoke test the FEC skill script from repo root.
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
- For skill changes, verify mirrored updates in both `.claude/skills/` and `.agents/skills/` and run the touched script (`uv run ...` for Python skills, `Rscript ...` for R skills).
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
- If a skill changes, note which directories were updated (`skills/`, `.claude/skills/`, `.agents/skills/`) and why.

## Security & Configuration Tips
- Set `FEC_API_KEY` or `DATA_GOV_API_KEY` in local environment only; never commit secrets.
- For `tidycensus` workflows, set `CENSUS_API_KEY` locally and never commit it.
- `.env`, `.venv`, and generated notebooks are ignored; keep large/raw data in the existing `data/` subfolders.


## Skills
Codex discovers repo-local skills from `.agents/skills/`, while Claude Code discovers active project skills from `.claude/skills/`. Do not duplicate the live skill catalog in this file; the current names, descriptions, and workflows live in each skill's own `SKILL.md`.

For skill changes, edit the canonical copy under `skills/` first, then mirror the same files into `.claude/skills/` and `.agents/skills/`. Validate the affected skill and run the touched script where practical.

Use a skill for focused repeatable workflows with instructions, references, and optional scripts. Use `AGENTS.md`/`CLAUDE.md` for always-on repo conventions, hooks/settings for mechanical enforcement, and plugins when a reusable workflow should be installed beyond this repo or bundled with connectors/MCP tools.
