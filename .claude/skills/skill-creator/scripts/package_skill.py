#!/usr/bin/env python3
"""
Skill Packager - Creates a zip archive of a skill folder

Usage:
    python skills/skill-creator/scripts/package_skill.py <path/to/skill-folder> [output-directory] [--target portable|codex|claude]

Example:
    python skills/skill-creator/scripts/package_skill.py skills/public/my-skill
    python skills/skill-creator/scripts/package_skill.py skills/public/my-skill ./dist
"""

import sys
import zipfile
import argparse
from pathlib import Path
from quick_validate import VALID_TARGETS, validate_skill


def should_exclude_file(file_path, skill_path):
    """Exclude transient files that should not be distributed."""
    relative_path = file_path.relative_to(skill_path)
    excluded_parts = {"__pycache__", ".git"}
    if any(part in excluded_parts for part in relative_path.parts):
        return True
    if file_path.suffix in {".pyc", ".pyo"}:
        return True
    if file_path.name in {".DS_Store"}:
        return True
    return False


def package_skill(skill_path, output_dir=None, target="portable"):
    """
    Package a skill folder into a zip file.

    Args:
        skill_path: Path to the skill folder
        output_dir: Optional output directory for the zip file (defaults to current directory)
        target: Validation target to use before packaging

    Returns:
        Path to the created zip file, or None if error
    """
    skill_path = Path(skill_path).resolve()

    # Validate skill folder exists
    if not skill_path.exists():
        print(f"❌ Error: Skill folder not found: {skill_path}")
        return None

    if not skill_path.is_dir():
        print(f"❌ Error: Path is not a directory: {skill_path}")
        return None

    # Validate SKILL.md exists
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        print(f"❌ Error: SKILL.md not found in {skill_path}")
        return None

    # Run validation before packaging
    print("🔍 Validating skill...")
    valid, message = validate_skill(skill_path, target=target)
    if not valid:
        print(f"❌ Validation failed: {message}")
        print("   Please fix the validation errors before packaging.")
        return None
    print(f"✅ {message}\n")

    # Determine output location
    skill_name = skill_path.name
    if output_dir:
        output_path = Path(output_dir).resolve()
        output_path.mkdir(parents=True, exist_ok=True)
    else:
        output_path = Path.cwd()

    zip_filename = output_path / f"{skill_name}.zip"

    # Create the zip file
    try:
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Walk through the skill directory
            for file_path in skill_path.rglob('*'):
                if file_path.is_file():
                    if should_exclude_file(file_path, skill_path):
                        continue
                    # Calculate the relative path within the zip
                    arcname = file_path.relative_to(skill_path.parent)
                    zipf.write(file_path, arcname)
                    print(f"  Added: {arcname}")

        print(f"\n✅ Successfully packaged skill to: {zip_filename}")
        return zip_filename

    except Exception as e:
        print(f"❌ Error creating zip file: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description="Package a skill folder into a zip archive.")
    parser.add_argument("skill_path", help="Path to the skill folder")
    parser.add_argument("output_dir", nargs="?", help="Optional output directory for the zip file")
    parser.add_argument(
        "--target",
        choices=sorted(VALID_TARGETS),
        default="portable",
        help="Validation target to use before packaging.",
    )
    args = parser.parse_args()

    print(f"📦 Packaging skill: {args.skill_path}")
    print(f"   Validation target: {args.target}")
    if args.output_dir:
        print(f"   Output directory: {args.output_dir}")
    print()

    result = package_skill(args.skill_path, args.output_dir, target=args.target)

    if result:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
