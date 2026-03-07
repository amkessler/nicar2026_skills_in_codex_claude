# FECFILE Skill Examples 

## Filing summary (summary-only)

Prompt:
`Analyze filing ID 1896830.`

Result (summary highlights):
- Committee: UTAH REPUBLICAN PARTY (C00089482)
- Form: F3XN, report code M6
- Coverage: 2025-05-01 to 2025-05-31
- This period: receipts $42,655.80; disbursements $21,283.49; cash on hand (end) $66,673.60
- Itemized individual contributions (this period): $28,563.25
- Unitemized individual contributions (this period): $2,363.55

## Largest expenditures (Schedule B)

Prompt:
`What are the largest expenditures?`

Result (itemized Schedule B, largest first):
```
Payee | Amount | Date | Purpose | Transaction ID
--- | --- | --- | --- | ---
Trump National Doral Hotel | $1,013.61 | 2025-05-19 | RNC training | SB21B.15039
Uber.com | $19.77 | 2025-05-06 | Travel -Cabfare | SB21B.15014
```

## Contributions by state (Schedule A)

Prompt:
`Show me a table of the contribution counts and totals, by state.`

Result (itemized Schedule A, all entities):
```
State | Count | Total
--- | --- | ---
UT | 32 | $35,042.25
VA | 2 | $2,400.00
GA | 1 | $750.00
MD | 2 | $750.00
MI | 1 | $750.00
FL | 1 | $600.00
```

## Top 10 contributions (Schedule A)

Prompt:
`Pull Schedule A and list the top 10 contributions.`

Result (top 10 itemized Schedule A contributions):
```
Name | State | Date | Amount | Purpose
--- | --- | --- | --- | ---
Utah State Tax Check Off | UT | 2025-05-14 | $11,729.00 | Other Receipts
Adams, Gregory | VA | 2025-05-06 | $1,650.00 | Receipt
Lyman, Phil | UT | 2025-05-12 | $1,500.00 | Receipt
Crandall, Gary | UT | 2025-05-19 | $1,031.24 | Receipt
Taylor, Stephen D | UT | 2025-05-19 | $1,031.24 | Receipt
Auxier, Tiara | UT | 2025-05-24 | $1,000.00 | Receipt
Chapman, Brian | UT | 2025-05-30 | $1,000.00 | Receipt
Cook, Allison | UT | 2025-05-16 | $1,000.00 | Receipt
Gray, Austin | UT | 2025-05-27 | $1,000.00 | Receipt
Harrison, James | UT | 2025-05-31 | $1,000.00 | Receipt
```

## Top 10 individual contributions (Schedule A, individuals only)

Prompt:
`Only individuals please.`

Result (top 10 itemized individual contributions):
```
Name | State | Date | Amount | Purpose
--- | --- | --- | --- | ---
Adams, Gregory | VA | 2025-05-06 | $1,650.00 | Receipt
Lyman, Phil | UT | 2025-05-12 | $1,500.00 | Receipt
Crandall, Gary | UT | 2025-05-19 | $1,031.24 | Receipt
Taylor, Stephen D | UT | 2025-05-19 | $1,031.24 | Receipt
Auxier, Tiara | UT | 2025-05-24 | $1,000.00 | Receipt
Chapman, Brian | UT | 2025-05-30 | $1,000.00 | Receipt
Cook, Allison | UT | 2025-05-16 | $1,000.00 | Receipt
Gray, Austin | UT | 2025-05-27 | $1,000.00 | Receipt
Harrison, James | UT | 2025-05-31 | $1,000.00 | Receipt
Hinkins, David | UT | 2025-05-09 | $1,000.00 | Receipt
```

---

## Filing summary (summary-only) — Committee: Ted Cruz for Senate

Prompt:
`I'd like to switch to examining filing 1932394 with the fecfile skill.`

Result (summary highlights):
- Committee: TED CRUZ FOR SENATE (C00492785)
- Form: F3A, report code Q3
- Coverage: 2025-07-01 to 2025-09-30
- This period: receipts $1,514,565.11; disbursements $1,294,498.03; cash on hand (end) $2,470,526.85
- Itemized individual contributions: $699,434.43
- Unitemized individual contributions: $479,111.42

## Biggest individual contributors (Schedule A)

Prompt:
`Who were the biggest individual contributors?`

Result (top individuals by total itemized contributions in the period):
```
Name | State | Total | Count | Max Single | Employer | Occupation
--- | --- | --- | --- | --- | --- | ---
HUANG, HUALIN | CA | $9,309.70 | 13 | $7,000.00 | NU CYBERTEK, INC. | SOFTWARE ENGINEER
MARCUS, STEPHEN | CA | $7,000.00 | 3 | $7,000.00 | RIOT VENTURES | VENTURE CAPITALIST
SCHWARZMAN, STEPHEN A. | NY | $7,000.00 | 3 | $7,000.00 | BLACKSTONE | C.E.O. & CHAIRMAN
DENICOLA, ANTHONY J. | FL | $7,000.00 | 3 | $7,000.00 | WCAS MANAGEMENT CORP. | CHAIRMAN
AQUILA, TONY | TX | $7,000.00 | 2 | $3,500.00 | SELF | TECH
HOFF, BETHANY | VA | $7,000.00 | 2 | $3,500.00 | COUPANG | MANAGER
LILLEY, JUSTIN W. | DC | $7,000.00 | 2 | $3,500.00 | TELE MEDIA POLICY CORP. | PRESIDENT
MCKENNA, ANDREW | VA | $7,000.00 | 2 | $3,500.00 | MCKENNA & ASSOCIATES | CEO
MCWILLIAMS, ANDREA | TX | $7,000.00 | 2 | $3,500.00 | MCWILLIAMS GOVT AFFAIRS | GOVT AFFAIRS
MERON, AMOS | CA | $7,000.00 | 2 | $3,500.00 | EMPYREAN CAPITAL PARTNERS LP | MANAGING PARTNER
```

## Top states for individual contributors (Schedule A)

Prompt:
`What are the top states for individual contributors?`

Result (top 10 by total itemized amount):
```
State | Count | Total
--- | --- | ---
TX | 5,753 | $349,122.85
CA | 1,863 | $96,852.08
FL | 1,168 | $69,660.46
VA | 422 | $59,777.82
NY | 644 | $48,957.94
MD | 134 | $31,989.96
PA | 374 | $26,951.42
GA | 487 | $22,379.19
DC | 26 | $20,281.00
CO | 227 | $18,939.21
```

---

## Filing summary (summary-only) — Committee: Trump Save America Joint Fundraising Committee

Prompt:
`Use the $fecfile skill to show me summary figures from filing 1873431`

Result (summary highlights):
- Committee: TRUMP SAVE AMERICA JOINT FUNDRAISING COMMITTEE (C00770941)
- Form: F3XN, report code YE
- Coverage: 2024-11-26 to 2024-12-31
- This period: receipts $2,091,027.34; disbursements $7,925,592.74; cash on hand (end) $7,183,384.73
- Itemized individual contributions (this period): $1,773,231.74
- Unitemized individual contributions (this period): $309,806.49

## Top 10 states for individual contributions (Schedule A)

Prompt:
`what are the top 10 state for individual contributions?`

Result (top 10 by total itemized amount):
```
State | Itemized contributions | Total amount
--- | --- | ---
VA | 1,450 | $1,994,616.00
TX | 7,536 | $220,993.69
CA | 7,440 | $214,324.63
FL | 6,481 | $182,539.71
NY | 2,828 | $82,291.00
AZ | 2,304 | $67,454.19
GA | 2,006 | $65,620.52
PA | 1,652 | $56,053.08
NC | 1,609 | $43,990.38
OH | 1,711 | $43,333.05
```

## Weekly individual contribution totals (Schedule A)

Prompt:
`for individual contributors, can you provide a breakdown by week of the total contributed?`

Result (weeks start Monday):
```
Week start | Week end | Itemized contributions | Total amount
--- | --- | --- | ---
2024-11-25 | 2024-12-01 | 10,677 | $379,891.26
2024-12-02 | 2024-12-08 | 11,580 | $756,524.20
2024-12-09 | 2024-12-15 | 10,957 | $618,740.96
2024-12-16 | 2024-12-22 | 13,054 | $731,991.64
2024-12-23 | 2024-12-29 | 12,725 | $768,539.06
2024-12-30 | 2025-01-05 | 3,186 | $488,679.75
```

## Transfers to affiliated/other party committees

Prompt:
`what was the total Transfers to Affiliated/Other Party Committees`

Result:
- This period (Column A): $7,820,342.32
- Year-to-date (Column B): $81,630,510.76

## Net contributions

Prompt:
`how much in Net Contributions was done in this filing`

Result:
- This period (Column A): $2,083,038.23
- Year-to-date (Column B): $115,186,499.12

## Contributions from individuals + party committees + other committees

Prompt:
`Can you sum the total of Individuals/Persons Other than Political Committees, Political Party Commitees, and Other Political Committees`

Result:
- This period (Column A): $2,083,038.23
- Year-to-date (Column B): $115,551,727.89
