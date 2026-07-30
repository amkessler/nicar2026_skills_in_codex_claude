#!/usr/bin/env python3
"""
Quick validation script for skills.
"""

import argparse
import re
import sys
from pathlib import Path


VALID_TARGETS = {"portable", "codex", "claude"}


def extract_frontmatter(content):
    """Return the YAML frontmatter body, or None when absent."""
    if not content.startswith("---"):
        return None

    match = re.match(r"^---\s*\n(.*?)\n---(?:\n|$)", content, re.DOTALL)
    if not match:
        raise ValueError("Invalid frontmatter format")
    return match.group(1)


def parse_frontmatter(frontmatter):
    """Parse simple top-level YAML key/value fields without external deps."""
    fields = {}
    for line in frontmatter.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[0].isspace() or ":" not in line:
            continue

        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip().strip("\"'")
    return fields


def validate_skill(skill_path, target="portable"):
    """Validate a skill for the requested target surface."""
    if target not in VALID_TARGETS:
        return False, f"Unknown target '{target}'. Expected one of: {', '.join(sorted(VALID_TARGETS))}"

    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    try:
        frontmatter = extract_frontmatter(content)
    except ValueError as exc:
        return False, str(exc)

    if frontmatter is None:
        if target == "claude":
            return True, "Skill is valid for claude target. No frontmatter found; Claude Code will use content defaults."
        return False, "No YAML frontmatter found. Portable and Codex skills require frontmatter with name and description."

    fields = parse_frontmatter(frontmatter)

    # Portable mode intentionally keeps the stricter cross-tool convention.
    if target in {"portable", "codex"}:
        if "name" not in fields or not fields["name"]:
            return False, "Missing 'name' in frontmatter"
        if "description" not in fields or not fields["description"]:
            return False, "Missing 'description' in frontmatter"

    name = fields.get("name")
    if name:
        if len(name) > 40:
            return False, "Name must be 40 characters or fewer"
        if not re.fullmatch(r"[a-z0-9-]+", name):
            return False, f"Name '{name}' should be hyphen-case (lowercase letters, digits, and hyphens only)"
        if name.startswith("-") or name.endswith("-") or "--" in name:
            return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
        if target in {"portable", "codex"} and name != skill_path.name:
            return False, f"Name '{name}' should match directory name '{skill_path.name}'"

    description = fields.get("description")
    if description:
        if "<" in description or ">" in description:
            return False, "Description cannot contain angle brackets (< or >)"
        if "[TODO" in description or "TODO" in description:
            return False, "Description still contains TODO placeholder text"

    return True, f"Skill is valid for {target} target!"


def main():
    parser = argparse.ArgumentParser(description="Validate a skill directory.")
    parser.add_argument("skill_directory", help="Path to the skill directory")
    parser.add_argument(
        "--target",
        choices=sorted(VALID_TARGETS),
        default="portable",
        help="Validation target. portable requires cross-tool name and description.",
    )
    args = parser.parse_args()

    valid, message = validate_skill(args.skill_directory, target=args.target)
    print(message)
    sys.exit(0 if valid else 1)


if __name__ == "__main__":
    main()
