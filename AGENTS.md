# Repository Guidelines

## Project Structure & Module Organization
This repo is a Python/Jupyter demo for NICAR 2026 focused on reusable AI skills.
- `fec_find_filings.py`: CLI to query OpenFEC filings by committee ID.
- `set_jupyter_kernel.py`: one-time local Jupyter kernel setup for this repo.
- `analysis/`: notebook work area; keep reusable templates in `analysis/notebook_templates/`.
- `data/`: project data buckets (`source/`, `processed/`, `public/`, `documentation/`, `html_reports/`).
- `skills/`: canonical teaching copy of all skills for workshop content.
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

## Coding Style & Naming Conventions
- Target Python `>=3.12` (see `pyproject.toml`), 4-space indentation, PEP 8 naming.
- Use `snake_case` for functions/variables and descriptive CLI flags.
- Prefer small, composable scripts with explicit `argparse` options and clear help text.
- Keep paths repo-relative and avoid hard-coded user-specific directories.

## Testing Guidelines
No formal `tests/` suite is present yet. Use script-level validation:
- Run `uv run python fec_find_filings.py ...` with small limits (`--limit 1` or `5`).
- Validate output modes you touch (`table`, `json`, `ndjson`, `csv`).
- For notebook/report changes, run `quarto render` and confirm output in `data/html_reports/`.
- For skill changes, verify mirrored updates in both `.claude/skills/` and `.codex/skills/` and run the touched script with `uv run`.

## Commit & Pull Request Guidelines
- Recent history uses short, direct subjects (for example: `tweak readme`, `migrate over skills files`).
- Keep commit messages imperative and scoped to one change.
- PRs should include: purpose, key files changed, commands run for verification, and any API/data assumptions.
- Link related issues/tasks and include rendered output screenshots only when UI/report layout changes.
- If a skill changes, note which directories were updated (`skills/`, `.claude/skills/`, `.codex/skills/`) and why.

## Security & Configuration Tips
- Set `FEC_API_KEY` or `DATA_GOV_API_KEY` in local environment only; never commit secrets.
- `.env`, `.venv`, and generated notebooks are ignored; keep large/raw data in the existing `data/` subfolders.
