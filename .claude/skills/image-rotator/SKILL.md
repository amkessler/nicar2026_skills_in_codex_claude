---
name: image-rotator
description: This skill should be used when users need to rotate images by 90 degrees. It handles image rotation tasks for common formats (PNG, JPG, JPEG, GIF, BMP, TIFF) using a reliable Python script that preserves image quality and supports both clockwise and counter-clockwise rotation.
---

# Image Rotator

## Overview

Rotate images by 90-degree increments while preserving quality. This skill provides a deterministic Python script for image rotation tasks, eliminating the need to rewrite image manipulation code.

## When to Use

Use this skill when users request:
- Rotating images by 90, 180, or 270 degrees
- Fixing image orientation
- Adjusting image alignment for documents or presentations
- Batch rotation operations

## Quick Start

The skill includes `scripts/rotate_image.py`, a command-line utility for rotating images. The script uses PIL/Pillow for reliable image processing.

### Basic Usage

Rotate an image clockwise by 90 degrees:

```bash
uv run python skills/image-rotator/scripts/rotate_image.py input.jpg
```

This creates `input_rotated.jpg` in the same directory.

### Common Options

**Specify output path:**
```bash
uv run python skills/image-rotator/scripts/rotate_image.py input.jpg --output rotated.jpg
```

**Rotate counter-clockwise:**
```bash
uv run python skills/image-rotator/scripts/rotate_image.py input.jpg --direction counter-clockwise
```

**Rotate 180 degrees (2x 90-degree rotations):**
```bash
uv run python skills/image-rotator/scripts/rotate_image.py input.jpg --times 2
```

**Rotate 270 degrees clockwise (or 90 counter-clockwise):**
```bash
uv run python skills/image-rotator/scripts/rotate_image.py input.jpg --times 3
```

### Supported Formats

- PNG
- JPG/JPEG
- GIF
- BMP
- TIFF

## Implementation Notes

### Prerequisites

The script requires Pillow (PIL fork):

```bash
uv add Pillow
```

### Script Details

The rotation script (`scripts/rotate_image.py`):
- Uses PIL's `rotate()` method with `expand=True` to prevent cropping
- Preserves image metadata when possible
- Returns clear success/error messages
- Handles edge cases (missing files, unsupported formats)

### Workflow

When users request image rotation:

1. Verify the input image path exists
2. Determine rotation direction and amount (default: 90 degrees clockwise)
3. Execute `scripts/rotate_image.py` with appropriate parameters
4. Report the output file location to the user

For batch operations, iterate through multiple images using the same script in a loop or shell command.

## Resources

### scripts/

- `rotate_image.py` - Main image rotation utility with CLI interface
