# Open-Meteo API Reference

## API Endpoint

`GET https://api.open-meteo.com/v1/forecast`

## Parameters

- `latitude`: Latitude coordinate (required)
- `longitude`: Longitude coordinate (required)
- `daily`: Comma-separated list of daily weather variables
- `temperature_unit`: fahrenheit or celsius
- `windspeed_unit`: mph, kmh, ms, or knots
- `timezone`: auto or specific timezone
- `forecast_days`: Number of days (1-16, default is 7)

## Daily Weather Variables

- `temperature_2m_max`: Maximum daily temperature
- `temperature_2m_min`: Minimum daily temperature
- `weathercode`: WMO weather code
- `windspeed_10m_max`: Maximum daily wind speed
- `winddirection_10m_dominant`: Dominant wind direction in degrees

## WMO Weather Codes

| Code | Description |
|------|-------------|
| 0 | Clear sky |
| 1 | Mainly clear |
| 2 | Partly cloudy |
| 3 | Overcast |
| 45 | Foggy |
| 48 | Depositing rime fog |
| 51 | Light drizzle |
| 53 | Moderate drizzle |
| 55 | Dense drizzle |
| 61 | Slight rain |
| 63 | Moderate rain |
| 65 | Heavy rain |
| 71 | Slight snow |
| 73 | Moderate snow |
| 75 | Heavy snow |
| 77 | Snow grains |
| 80 | Slight rain showers |
| 81 | Moderate rain showers |
| 82 | Violent rain showers |
| 85 | Slight snow showers |
| 86 | Heavy snow showers |
| 95 | Thunderstorm |
| 96 | Thunderstorm with slight hail |
| 99 | Thunderstorm with heavy hail |

## Response Structure

```json
{
  "latitude": 47.6062,
  "longitude": -122.3321,
  "daily": {
    "time": ["2025-10-17", "2025-10-18", ...],
    "temperature_2m_max": [68.5, 70.2, ...],
    "temperature_2m_min": [48.1, 50.3, ...],
    "weathercode": [1, 0, ...],
    "windspeed_10m_max": [10.2, 8.5, ...],
    "winddirection_10m_dominant": [225, 180, ...]
  }
}
```

## Important Notes

- **No API Key**: Open-Meteo is free and requires no authentication
- **No Rate Limits**: Free tier has generous usage limits
- **Global Coverage**: Works for any location worldwide
- **Data Source**: Combines weather models from multiple national weather providers
- **Update Frequency**: Models are updated hourly with new forecast data
- **License**: Data is provided under CC BY 4.0 license

## More Information

Full API documentation: https://open-meteo.com/en/docs
