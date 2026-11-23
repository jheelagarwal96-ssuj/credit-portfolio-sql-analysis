# Power BI Build Guide: Credit Portfolio Dashboard

Build time: about 2 hours. Data: `data/customers.csv`, `data/loans.csv`, `data/repayments.csv` (synthetic, as-of 30 Sep 2026).
Note: Power BI Desktop runs on Windows only. On a Mac, use a Windows PC/lab, a cloud VM, or a college computer.

## Step 1. Load data
Home > Get data > Text/CSV. Load all three files. In Power Query check types:
- `loan_amount`, `emi_amount`, `paid_amount`, `credit_score`, `days_past_due`, `installment_no`: Whole number
- `interest_rate`: Decimal number
- `disbursal_date`, `due_date`, `paid_date`: Date
Close & Apply.

## Step 2. Create a Date table
Modeling > New table:
```
Date =
ADDCOLUMNS(
    CALENDAR(DATE(2024,1,1), DATE(2026,12,31)),
    "Year", YEAR([Date]),
    "Quarter", "Q" & ROUNDUP(MONTH([Date])/3,0) & " " & YEAR([Date]),
    "Month", FORMAT([Date],"MMM YY"),
    "Month Sort", YEAR([Date])*100 + MONTH([Date])
)
```
Select the `Month` column > Column tools > Sort by column > `Month Sort`. Then Table tools > Mark as date table.

## Step 3. Relationships (Model view)
| From (one side) | To (many side) |
|---|---|
| customers[customer_id] | loans[customer_id] |
| loans[loan_id] | repayments[loan_id] |
| Date[Date] | loans[disbursal_date] |

All single direction, one-to-many.

## Step 4. Calculated columns
On `loans`:
```
Current DPD =
VAR d = CALCULATE(MAX(repayments[days_past_due]), repayments[paid_date] = BLANK())
RETURN COALESCE(d, 0)
```
```
DPD Bucket =
SWITCH(TRUE(),
    loans[Current DPD] = 0,  "0 (current)",
    loans[Current DPD] <= 30, "1-30",
    loans[Current DPD] <= 60, "31-60",
    loans[Current DPD] <= 90, "61-90",
    "90+")
```
On `customers`:
```
Score Band =
SWITCH(TRUE(),
    customers[credit_score] < 600, "1. Below 600",
    customers[credit_score] < 700, "2. 600-699",
    customers[credit_score] < 750, "3. 700-749",
    "4. 750+")
```

## Step 5. Measures
Create a table called `_Measures` (Enter data, blank) and add:
```
Total Loans = COUNTROWS(loans)
Total Disbursed = SUM(loans[loan_amount])
Avg Ticket Size = DIVIDE([Total Disbursed], [Total Loans])
Weighted Avg Rate = DIVIDE(SUMX(loans, loans[loan_amount] * loans[interest_rate]), [Total Disbursed])
Defaulted Loans = CALCULATE([Total Loans], loans[status] = "Defaulted")
Default Rate = DIVIDE([Defaulted Loans], [Total Loans])
Live Exposure = CALCULATE([Total Disbursed], loans[status] <> "Closed")
Exposure Over 30 DPD = CALCULATE([Total Disbursed], loans[status] <> "Closed", loans[Current DPD] > 30)
PAR 30 % = DIVIDE([Exposure Over 30 DPD], [Live Exposure])
Disbursed Prev Month = CALCULATE([Total Disbursed], DATEADD('Date'[Date], -1, MONTH))
Disbursed MoM % = DIVIDE([Total Disbursed] - [Disbursed Prev Month], [Disbursed Prev Month])
Disbursed YTD = TOTALYTD([Total Disbursed], 'Date'[Date])
Late Payment % =
DIVIDE(
    CALCULATE(COUNTROWS(repayments), repayments[days_past_due] > 10, repayments[paid_date] <> BLANK()),
    COUNTROWS(repayments))
```
Format: `Default Rate`, `PAR 30 %`, `Disbursed MoM %`, `Late Payment %` as percentage (1 decimal).

## Step 6. Page 1: Portfolio Overview
- **Top row, 5 cards:** Total Disbursed, Total Loans, Default Rate, PAR 30 %, Weighted Avg Rate.
- **Line chart:** X = Date[Month], Y = Total Disbursed (tooltip: Disbursed MoM %).
- **Bar chart:** Y = loans[product_type], X = Default Rate (sort descending).
- **Bar chart:** Y = customers[city], X = Total Disbursed; add Default Rate in tooltips.
- **Slicers:** Date[Year], loans[product_type], customers[city], customers[income_band].

## Step 7. Page 2: Risk Deep-Dive
- **Column chart:** X = customers[Score Band], Y = Default Rate.
- **Column chart:** X = loans[DPD Bucket], Y = Live Exposure.
- **Line chart:** X = Date[Quarter], Y = Default Rate (vintage view).
- **Table:** loan_id, product_type, loan_amount, Current DPD, filtered to Current DPD > 30 (top N by loan_amount).
- Same slicers, synced across pages (View > Sync slicers).

## Step 8. Polish and publish
- One colour theme, consistent fonts, titles that state the insight (not just "Default Rate by Product").
- Add a text box with 3 key insights (see README).
- Take a screenshot of each page for LinkedIn/GitHub. Publish to Power BI Service only if you have a work/school account.

## Sanity checks (your numbers should match)
| Measure (no filters) | Expected |
|---|---|
| Total Loans | 1,800 |
| Total Disbursed | 1,478,165,000 |
| Default Rate | 8.7% (156 of 1,800) |
| Personal Loan default rate | 12.8% |
| Home Loan default rate | 1.8% |
If they match the SQL results in `2_SQL_Credit_Portfolio_Queries.sql`, your model is correct.
