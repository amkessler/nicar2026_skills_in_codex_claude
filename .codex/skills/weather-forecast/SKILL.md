---
name: weather-forecast
description: Fetch 7-day weather forecasts from Open-Meteo API. ALWAYS use get_coordinates.py first when given city names to look up coordinates, then use get_forecast.py with those coordinates. Use for weather forecasts, weather data, or temperature trends.
---

# Weather Forecast Skill

This skill fetches 7-day weather forecasts from the Open-Meteo API and presents the data in both table and chart formats.

## When to Use This Skill

Use this skill when:
- User requests a weather forecast for any location worldwide
- User wants to see temperature trends or weather data
- User asks for a visual representation of weather conditions
- User specifies a city name or coordinates

## Standard Workflow - IMPORTANT

**When given a city name, ALWAYS follow this two-step process:**

1. **Use get_coordinates.py to geocode the location** (DO NOT use built-in knowledge)
   ```bash
   uv run python skills/weather-forecast/scripts/get_coordinates.py "City, State"
   ```

2. **Use those coordinates with get_forecast.py**
   ```bash
   uv run python skills/weather-forecast/scripts/get_forecast.py <lat> <lon>
   ```

**DO NOT**: Hardcode coordinates from training data or external knowledge. Always use the get_coordinates.py script to ensure the skill is self-contained and reproducible.

## Prerequisites

The script requires the `requests` library. Install if needed:
```bash
pip install requests --break-system-packages
```

## Workflow

### Option A: Using City Names (US Cities Only)

For the 1000 largest US cities, use the `get_coordinates.py` helper script:

**Step 1: Get coordinates from city name**
```bash
python skills/weather-forecast/scripts/get_coordinates.py "City, State"
```

Accepts formats:
- "Philadelphia, PA" (city, state abbreviation)
- "Trenton, New Jersey" (city, full state name)
- "Denver" "CO" (separate arguments)

**Step 2: Get forecast using the coordinates**
```bash
# Combined workflow
python skills/weather-forecast/scripts/get_forecast.py $(python skills/weather-forecast/scripts/get_coordinates.py "Philadelphia, PA")
```

### Option B: Using Coordinates Directly

For international locations or US cities not in the database:

**Step 1: Get Coordinates**
- Search the web for "{city name} coordinates" to find the lat/lon
- Or ask the user to provide coordinates directly

**Step 2: Run the Forecast Script**

Execute the script with coordinates:
```bash
python skills/weather-forecast/scripts/get_forecast.py <latitude> <longitude>
```

For JSON output (used for charting):
```bash
python skills/weather-forecast/scripts/get_forecast.py <latitude> <longitude> --json
```

### Step 3: Present Results

The script outputs forecast data in two formats:

**Table Format (default)**: A formatted text table showing:
- Period names (Today, Tonight, Monday, etc.)
- Temperature (high for day, low for night)
- Wind speed and direction
- Short forecast description

**JSON Format (--json flag)**: Structured data suitable for creating visualizations including:
- All forecast fields
- Temperature values for charting
- Day/night indicators

### Step 4: Create Visualizations

After getting JSON data, create visual representations:

1. **Temperature Chart**: Line or bar chart showing temperature trends across the 7-day period
2. **Condition Summary**: Visual representation of weather conditions (clear, cloudy, rainy, etc.)

Use appropriate charting libraries or create React/HTML artifacts to display the data visually.

## Example Usage

### Using City Names (US Cities)

```bash
# Get coordinates for a US city
python skills/weather-forecast/scripts/get_coordinates.py "Philadelphia, PA"
# Output: 39.9525839 -75.1652215

# Get forecast using city name (combined)
python skills/weather-forecast/scripts/get_forecast.py $(python skills/weather-forecast/scripts/get_coordinates.py "Denver, CO")

# Alternative format with full state name
python skills/weather-forecast/scripts/get_coordinates.py "Trenton" "New Jersey"

# Verbose output shows city confirmation
python skills/weather-forecast/scripts/get_coordinates.py "Seattle, WA" --verbose
# Output: Seattle, WA: 47.6062095 -122.3320708
```

### Using Coordinates Directly

```bash
# Example: Denver, CO (39.7392, -104.9903)
python skills/weather-forecast/scripts/get_forecast.py 39.7392 -104.9903

# Example: Get JSON for charting
python skills/weather-forecast/scripts/get_forecast.py 39.7392 -104.9903 --json

# Example: International location (Tokyo, Japan)
python skills/weather-forecast/scripts/get_forecast.py 35.6762 139.6503
```

## Important Notes

- **Worldwide Coverage**: Open-Meteo API covers any location globally
- **No API Key Required**: Open-Meteo is free and requires no authentication
- **US City Database**: The `get_coordinates.py` script includes the 1000 largest US cities (no network needed for lookups)
- **City Lookup Limitations**: For smaller US cities or international locations, use coordinates directly
- **State Required**: City names require state specification to avoid ambiguity (e.g., "Springfield, MA" vs "Springfield, IL")
- **Flexible State Format**: Accepts both state abbreviations (PA, NJ) and full names (Pennsylvania, New Jersey)
- **Network Access**: The `get_forecast.py` script requires internet access to query the Open-Meteo API
- **Data Freshness**: Forecasts are updated regularly throughout the day
- **WMO Weather Codes**: The script translates WMO weather codes to readable descriptions

## Sample Output

**Table format**:
```
Period               Temp       Wind            Forecast
-----------------------------------------------------------------------------------------------
Today                68°F       10 mph SW       Mainly clear
Tonight              48°F       10 mph SW       Mainly clear
Monday               72°F       8 mph S         Clear sky
Monday Night         52°F       8 mph S         Clear sky
```

**JSON format**: Array of forecast objects with complete weather data for visualization.

## References

See `references/api_reference.md` for detailed API documentation and WMO weather code descriptions.
