# Source

- Dataset: U.S. Census Bureau ACS 5-year county-level extracts
- Pulled: 2026-03-01
- Endpoints:
  - `https://api.census.gov/data/2010/acs/acs5?get=NAME,B01003_001E,B03002_003E&for=county:*&in=state:*`
  - `https://api.census.gov/data/2020/acs/acs5?get=NAME,B01003_001E,B03002_003E&for=county:*&in=state:*`
- Output files:
  - `county_race_acs5_2010.csv`
  - `county_race_acs5_2020.csv`
- Output columns:
  `county_fips,state,county,total_population,non_hispanic_white`
- Notes:
  `non_hispanic_white` uses ACS variable `B03002_003E` (Not Hispanic or Latino: White alone).
