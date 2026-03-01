#!/usr/bin/env python3
"""
Fetch 7-day weather forecast from Open-Meteo API and display as table and chart.
"""

import requests
import json
import sys
from datetime import datetime


def get_weather_code_description(code):
    """Convert WMO weather code to description."""
    weather_codes = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Foggy",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        71: "Slight snow",
        73: "Moderate snow",
        75: "Heavy snow",
        77: "Snow grains",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        85: "Slight snow showers",
        86: "Heavy snow showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        99: "Thunderstorm with heavy hail"
    }
    return weather_codes.get(code, "Unknown")


def get_wind_direction(degrees):
    """Convert wind direction degrees to cardinal direction."""
    directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                  "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    index = round(degrees / 22.5) % 16
    return directions[index]


def get_forecast(lat, lon):
    """Get weather forecast from Open-Meteo API."""
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "weathercode",
            "windspeed_10m_max",
            "winddirection_10m_dominant"
        ],
        "temperature_unit": "fahrenheit",
        "windspeed_unit": "mph",
        "timezone": "auto",
        "forecast_days": 7
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Parse the forecast data into periods (day/night for 7 days)
        periods = []
        daily = data["daily"]
        
        for i in range(7):
            date = datetime.fromisoformat(daily["time"][i])
            day_name = date.strftime("%A")
            
            # Day period
            temp_max = round(daily["temperature_2m_max"][i])
            weather_code = daily["weathercode"][i]
            wind_speed = round(daily["windspeed_10m_max"][i])
            wind_dir = get_wind_direction(daily["winddirection_10m_dominant"][i])
            forecast = get_weather_code_description(weather_code)
            
            periods.append({
                "name": day_name if i > 0 else "Today",
                "temperature": temp_max,
                "temperatureUnit": "F",
                "windSpeed": f"{wind_speed} mph",
                "windDirection": wind_dir,
                "shortForecast": forecast,
                "detailedForecast": f"{forecast} with a high of {temp_max}°F. Winds {wind_dir} at {wind_speed} mph.",
                "isDaytime": True
            })
            
            # Night period
            temp_min = round(daily["temperature_2m_min"][i])
            night_name = f"{day_name} Night" if i > 0 else "Tonight"
            
            periods.append({
                "name": night_name,
                "temperature": temp_min,
                "temperatureUnit": "F",
                "windSpeed": f"{wind_speed} mph",
                "windDirection": wind_dir,
                "shortForecast": forecast,
                "detailedForecast": f"{forecast} with a low of {temp_min}°F. Winds {wind_dir} at {wind_speed} mph.",
                "isDaytime": False
            })
        
        return periods
        
    except Exception as e:
        print(f"Forecast API error: {e}", file=sys.stderr)
        return None


def format_table(periods):
    """Format forecast data as a text table."""
    # Print header
    print(f"{'Period':<20} {'Temp':<10} {'Wind':<15} {'Forecast':<50}")
    print("-" * 95)
    
    # Print each period (limit to 14 periods = 7 days)
    for period in periods[:14]:
        name = period["name"]
        temp = f"{period['temperature']}°{period['temperatureUnit']}"
        wind = f"{period['windSpeed']} {period['windDirection']}"
        forecast = period["shortForecast"]
        
        # Truncate forecast if too long
        if len(forecast) > 47:
            forecast = forecast[:44] + "..."
        
        print(f"{name:<20} {temp:<10} {wind:<15} {forecast:<50}")


def format_json(periods):
    """Format forecast data as JSON for chart visualization."""
    chart_data = []
    for period in periods[:14]:  # 7 days = 14 periods (day + night)
        chart_data.append({
            "name": period["name"],
            "temperature": period["temperature"],
            "temperatureUnit": period["temperatureUnit"],
            "windSpeed": period["windSpeed"],
            "windDirection": period["windDirection"],
            "shortForecast": period["shortForecast"],
            "detailedForecast": period["detailedForecast"],
            "isDaytime": period["isDaytime"]
        })
    return chart_data


def main():
    if len(sys.argv) < 3:
        print("Usage: python get_forecast.py <latitude> <longitude> [--json]", file=sys.stderr)
        print("Example: python get_forecast.py 39.7392 -104.9903", file=sys.stderr)
        print("\nOptions:", file=sys.stderr)
        print("  --json    Output as JSON for charting", file=sys.stderr)
        sys.exit(1)
    
    try:
        lat = float(sys.argv[1])
        lon = float(sys.argv[2])
    except ValueError:
        print("Error: Latitude and longitude must be valid numbers", file=sys.stderr)
        sys.exit(1)
    
    output_json = "--json" in sys.argv
    
    if not output_json:
        print(f"Coordinates: {lat}, {lon}")
        print("Fetching 7-day forecast from Open-Meteo...\n")
    
    periods = get_forecast(lat, lon)
    
    if periods is None or len(periods) == 0:
        print("Error: Could not fetch forecast data", file=sys.stderr)
        sys.exit(1)
    
    if output_json:
        # Output JSON for chart visualization
        chart_data = format_json(periods)
        print(json.dumps(chart_data, indent=2))
    else:
        # Output as table
        format_table(periods)


if __name__ == "__main__":
    main()
