#!/usr/bin/env python3
"""
Get latitude and longitude coordinates for US cities.

IMPORTANT FOR CLAUDE CODE:
This script should ALWAYS be used when Claude receives a city name.
Do not use built-in geographic knowledge or hardcoded coordinates.
Use this geocoding script instead to ensure the skill is self-contained
and reproducible.

Usage:
    python get_coordinates.py "City, State"
    python get_coordinates.py "City" "State"

Examples:
    python get_coordinates.py "Philadelphia, PA"
    python get_coordinates.py "Trenton" "New Jersey"
    python get_coordinates.py "Denver, CO" --verbose
"""

import json
import sys
from pathlib import Path


# US state abbreviations mapping (both directions)
STATE_ABBREV = {
    'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR',
    'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE',
    'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI', 'Idaho': 'ID',
    'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA', 'Kansas': 'KS',
    'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD',
    'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS',
    'Missouri': 'MO', 'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
    'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY',
    'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK',
    'Oregon': 'OR', 'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
    'South Dakota': 'SD', 'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT',
    'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
    'Wisconsin': 'WI', 'Wyoming': 'WY', 'District of Columbia': 'DC'
}

# Create reverse mapping (abbreviation to full name)
ABBREV_TO_STATE = {abbrev: state for state, abbrev in STATE_ABBREV.items()}


def normalize_state(state_input):
    """
    Normalize state input to full state name.
    Accepts both abbreviations (PA, NJ) and full names (Pennsylvania, New Jersey).

    Returns: Full state name or None if not found
    """
    state_input = state_input.strip()

    # Try as abbreviation first (case insensitive)
    state_upper = state_input.upper()
    if state_upper in ABBREV_TO_STATE:
        return ABBREV_TO_STATE[state_upper]

    # Try as full name (case insensitive)
    for full_name in STATE_ABBREV.keys():
        if full_name.lower() == state_input.lower():
            return full_name

    return None


def load_cities_database():
    """Load the US cities database from JSON file."""
    # Get path relative to this script
    script_dir = Path(__file__).parent
    data_file = script_dir.parent / 'data' / 'us_cities.json'

    if not data_file.exists():
        print(f"Error: Cities database not found at {data_file}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(data_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading cities database: {e}", file=sys.stderr)
        sys.exit(1)


def find_city_coordinates(city_name, normalized_state, cities_data):
    """
    Find coordinates for a city in a specific state.

    Returns: (latitude, longitude) tuple or None if not found
    """
    city_name = city_name.strip()

    # Search for matching city
    for city_data in cities_data:
        if (city_data['city'].lower() == city_name.lower() and
            city_data['state'].lower() == normalized_state.lower()):
            return (city_data['latitude'], city_data['longitude'])

    return None


def parse_arguments():
    """
    Parse command line arguments.
    Supports formats:
    - "City, State"
    - "City" "State"
    - Either with optional --verbose flag

    Returns: (city, state, verbose) tuple
    """
    verbose = '--verbose' in sys.argv
    args = [arg for arg in sys.argv[1:] if arg != '--verbose']

    if len(args) == 0:
        return None, None, verbose

    # Single argument: "City, State" format
    if len(args) == 1:
        parts = args[0].split(',')
        if len(parts) == 2:
            return parts[0].strip(), parts[1].strip(), verbose
        else:
            # Try space-separated (last word is state)
            words = args[0].split()
            if len(words) >= 2:
                state = words[-1]
                city = ' '.join(words[:-1])
                return city, state, verbose
            else:
                return None, None, verbose

    # Two arguments: "City" "State" format
    elif len(args) == 2:
        return args[0].strip(), args[1].strip(), verbose

    return None, None, verbose


def main():
    city, state, verbose = parse_arguments()

    if not city or not state:
        print("Usage: python get_coordinates.py <city> <state> [--verbose]", file=sys.stderr)
        print("", file=sys.stderr)
        print("Examples:", file=sys.stderr)
        print('  python get_coordinates.py "Philadelphia, PA"', file=sys.stderr)
        print('  python get_coordinates.py "Trenton" "New Jersey"', file=sys.stderr)
        print('  python get_coordinates.py "Denver, CO" --verbose', file=sys.stderr)
        print("", file=sys.stderr)
        print("Supports state abbreviations (PA, NJ) or full names (Pennsylvania, New Jersey)", file=sys.stderr)
        sys.exit(1)

    normalized_state = normalize_state(state)
    if not normalized_state:
        print(f"Error: Unknown state '{state}'", file=sys.stderr)
        print("Please use state abbreviation (e.g., PA, NJ) or full name (e.g., Pennsylvania, New Jersey)", file=sys.stderr)
        sys.exit(1)

    # Load cities database
    cities_data = load_cities_database()

    # Find coordinates
    coords = find_city_coordinates(city, normalized_state, cities_data)

    if coords:
        lat, lon = coords
        if verbose:
            print(f"{city}, {state}: {lat} {lon}")
        else:
            print(f"{lat} {lon}")
    else:
        print(f"Error: City '{city}, {normalized_state}' not found in database", file=sys.stderr)
        print(f"", file=sys.stderr)
        print(f"The database contains the 1000 largest US cities.", file=sys.stderr)
        print(f"For smaller cities, please use coordinates directly with get_forecast.py", file=sys.stderr)
        print(f"", file=sys.stderr)
        print(f"Find coordinates at: https://www.latlong.net/", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
