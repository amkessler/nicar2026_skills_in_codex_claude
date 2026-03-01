# Source

- Dataset: U.S. Census Bureau ACS 5-year (2023) county-level extract
- Pulled: 2026-03-01
- Endpoint:
  `https://api.census.gov/data/2023/acs/acs5?get=NAME,B01003_001E,B19013_001E,B17001_001E,B17001_002E,B01002_001E,B25064_001E&for=county:*&in=state:*`
- Output file:
  `county_demographics_acs5_2023.csv`
- Output columns:
  `county_fips,state,county,total_population,median_household_income,poverty_rate,median_age,median_gross_rent`
- Notes:
  `poverty_rate` is computed as `(B17001_002E / B17001_001E) * 100`.
