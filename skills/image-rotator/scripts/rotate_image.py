#!/usr/bin/env python3
"""
Rotate an image by 90 degrees (clockwise or counter-clockwise).

This script uses PIL/Pillow to rotate images while preserving quality.
Supports common image formats: PNG, JPG, JPEG, GIF, BMP, TIFF.
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow library is required. Install with: uv add Pillow")
    sys.exit(1)


def rotate_image(input_path, output_path=None, direction="clockwise", times=1):
    """
    Rotate an image by 90 degrees.

    Args:
        input_path: Path to the input image
        output_path: Path to save the rotated image (optional, defaults to input_rotated.ext)
        direction: "clockwise" or "counter-clockwise" (or "cw"/"ccw")
        times: Number of 90-degree rotations (1-3)

    Returns:
        Path to the output file
    """
    input_path = Path(input_path)

    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    # Load the image
    img = Image.open(input_path)

    # Determine rotation angle
    # PIL's rotate() uses counter-clockwise, so we need to adjust
    if direction.lower() in ["clockwise", "cw"]:
        angle = -90 * times  # Negative for clockwise
    else:  # counter-clockwise
        angle = 90 * times

    # Rotate the image
    # expand=True ensures the image isn't cropped
    rotated_img = img.rotate(angle, expand=True)

    # Determine output path
    if output_path is None:
        stem = input_path.stem
        suffix = input_path.suffix
        output_path = input_path.parent / f"{stem}_rotated{suffix}"
    else:
        output_path = Path(output_path)

    # Save the rotated image
    rotated_img.save(output_path)

    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Rotate an image by 90 degrees",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Rotate clockwise by 90 degrees
  %(prog)s input.jpg

  # Rotate counter-clockwise
  %(prog)s input.jpg --direction counter-clockwise

  # Rotate 180 degrees (2 times)
  %(prog)s input.jpg --times 2

  # Specify output path
  %(prog)s input.jpg --output rotated.jpg
        """
    )

    parser.add_argument(
        "input",
        help="Path to the input image file"
    )

    parser.add_argument(
        "-o", "--output",
        help="Path to save the rotated image (default: input_rotated.ext)"
    )

    parser.add_argument(
        "-d", "--direction",
        choices=["clockwise", "cw", "counter-clockwise", "ccw"],
        default="clockwise",
        help="Rotation direction (default: clockwise)"
    )

    parser.add_argument(
        "-t", "--times",
        type=int,
        choices=[1, 2, 3],
        default=1,
        help="Number of 90-degree rotations (default: 1)"
    )

    args = parser.parse_args()

    try:
        output_path = rotate_image(
            args.input,
            args.output,
            args.direction,
            args.times
        )
        print(f"✓ Image rotated successfully")
        print(f"  Input:  {args.input}")
        print(f"  Output: {output_path}")

    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
