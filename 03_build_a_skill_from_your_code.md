# Build A Skill From Your Own R/Python Code

This tutorial walks you through turning existing code into a reusable skill.
Use this when you already have working scripts and want the assistant to run them reliably.

## What You Are Building

By the end, you will have:
1. A new skill folder under `skills/`
2. A `SKILL.md` with clear trigger conditions and workflow steps
3. One or more scripts in `scripts/` (Python and/or R)
4. A packaged zip you can share

## Prerequisites

From repo root:

```bash
uv sync
```

If your skill includes R code, ensure `Rscript` is available:

```bash
Rscript --version
```

## Step 1: Pick A Good Script Candidate

Choose code that is:
- Repeated often
- Error-prone when rewritten manually
- Easy to run from CLI
- Produces stable outputs (CSV, JSON, table)

Good examples:
- Clean and standardize campaign finance records
- Aggregate contributions by week/state
- Convert source files into reporting-ready tables

## Step 2: Make Your Script CLI-Friendly

Skills work best when scripts can run with explicit arguments.

### Python pattern

Use `argparse`, accept input/output paths, print clear errors.

```python
#!/usr/bin/env python3
import argparse
import pandas as pd

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    df = pd.read_csv(args.input)
    out = (
        df.groupby("state", dropna=False)["amount"]
        .sum()
        .reset_index()
        .sort_values("amount", ascending=False)
    )
    out.to_csv(args.output, index=False)
    print(f"Wrote {len(out)} rows to {args.output}")

if __name__ == "__main__":
    main()
```

### R pattern

Use `commandArgs(trailingOnly = TRUE)`, validate required args, and write output deterministically.

```r
#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript summarize_state_totals.R <input.csv> <output.csv>")
}

input_path <- args[1]
output_path <- args[2]

library(readr)
library(dplyr)
library(stringr)

df <- read_csv(input_path, show_col_types = FALSE)
agg <- df %>%
  group_by(state) %>%
  summarise(amount = sum(amount, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(amount))

write_csv(agg, output_path)
message(str_c("Wrote ", nrow(agg), " rows to ", output_path))
```

## Step 3: Scaffold A New Skill

Initialize a new folder using the included helper:

```bash
uv run python skills/skill-creator/scripts/init_skill.py campaign-cleaner --path skills
```

You should now have:

```text
skills/campaign-cleaner/
  SKILL.md
  scripts/
  references/
  assets/
```

## Step 4: Add Your Real Scripts

Replace example files with your own:

1. Put Python scripts in `skills/campaign-cleaner/scripts/`
2. Put R scripts in `skills/campaign-cleaner/scripts/`
3. Make them executable if needed:

```bash
chmod +x skills/campaign-cleaner/scripts/*.py
chmod +x skills/campaign-cleaner/scripts/*.R
```

Optional: add tiny sample input data for testing in `assets/`.

## Step 5: Write A Strong SKILL.md

Edit:

```text
skills/campaign-cleaner/SKILL.md
```

Minimum requirements:
1. Frontmatter `name` and `description`
2. Clear trigger language in description
3. Exact run order and command examples
4. Required arguments and expected outputs
5. Safety rules (for example, never overwrite source files)

### Example frontmatter

```yaml
---
name: campaign-cleaner
description: This skill should be used when users need to clean and aggregate campaign finance CSV data using the newsroom's Python and R scripts.
---
```

### Example workflow section

```md
## Standard Workflow

1. Validate input file exists.
2. Run Python cleaner:
   `uv run python skills/campaign-cleaner/scripts/clean_transactions.py --input <in.csv> --output <clean.csv>`
3. Run R summary:
   `Rscript skills/campaign-cleaner/scripts/summarize_state_totals.R <clean.csv> <summary.csv>`
4. Present top rows and key totals.
```

## Step 6: Add References For Field Definitions

Put data dictionaries and schema notes in:

```text
skills/campaign-cleaner/references/
```

Example files:
- `references/SCHEMA.md`
- `references/KNOWN_EDGE_CASES.md`

These help the assistant avoid guessing column names and business logic.

## Step 7: Test The Scripts Directly

Before testing auto-trigger behavior, run scripts by hand.

Python example:

```bash
uv run python skills/campaign-cleaner/scripts/clean_transactions.py \
  --input data/source/sample.csv \
  --output data/processed/clean.csv
```

R example:

```bash
Rscript skills/campaign-cleaner/scripts/summarize_state_totals.R \
  data/processed/clean.csv \
  data/processed/state_totals.csv
```

If these fail, fix scripts first. Do not debug SKILL.md until scripts run correctly.

## Step 8: Validate And Package

Validate:

```bash
uv run python skills/skill-creator/scripts/quick_validate.py skills/campaign-cleaner
```

Package:

```bash
uv run python skills/skill-creator/scripts/package_skill.py skills/campaign-cleaner ./dist
```

Expected output:
- `dist/campaign-cleaner.zip`

## Step 9: Mirror Into Active Skill Directories

`skills/` is the session/canonical copy. To actively use the skill in both tools, copy to:
- `.claude/skills/`
- `.codex/skills/`

Example:

```bash
cp -R skills/campaign-cleaner .claude/skills/campaign-cleaner
cp -R skills/campaign-cleaner .codex/skills/campaign-cleaner
```

## Step 10: Test In Assistant Chats

Try prompts that should trigger the skill:

- "Clean this campaign CSV and summarize totals by state."
- "Use the campaign-cleaner skill to process `data/source/may_transactions.csv`."
- "Run the Python cleaner, then R summarizer, and show top 10 states by amount."

If triggering is inconsistent:
1. Make `description` in frontmatter more specific.
2. Add an explicit "When to use this skill" section.
3. Include exact phrasing examples.

## Common Pitfalls

- Script has hidden notebook assumptions (cwd, globals, interactive state)
- Missing CLI args; script only works when edited manually
- Output format changes run-to-run
- SKILL.md does not specify run order for Python + R steps
- Missing dependencies (Python packages or R packages)

## Simple Quality Checklist

Before sharing the skill:
- Script commands run from repo root
- Inputs/outputs are explicit arguments
- Errors are readable
- SKILL.md has deterministic order of operations
- Validation passes
- Zip package builds successfully
