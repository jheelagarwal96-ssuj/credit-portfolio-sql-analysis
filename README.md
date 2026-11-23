# Proof of Work: Excel, Financial Modelling, SQL, Power BI

Built for a finance / business analytics internship portfolio. Three projects:

| # | Skill | File | What it shows |
|---|---|---|---|
| 1 | Excel + Financial modelling | `1_Excel_Financial_Model_DCF.xlsx` | Historical financials, ratio and DuPont analysis, 5-year FCFF projections, WACC (CAPM), DCF, sensitivity grid, summary chart |
| 2 | SQL | `2_SQL_Credit_Portfolio_Queries.sql` + `data/` | 13 queries on a loan portfolio: JOINs, GROUP BY/HAVING, CTEs, window functions (SUM OVER, LAG, ROW_NUMBER, NTILE), delinquency buckets, vintage analysis |
| 3 | Power BI | `3_PowerBI_Build_Guide.md` + `data/` | Data model, DAX measures and a 2-page dashboard spec. **You build the .pbix yourself (2 hrs)** |

## Be honest about the data (this matters in interviews)
- Project 1 uses a **fictional company**. Before it counts as proof of work, replace the blue inputs on the `Historical` sheet with a real listed company's data (Screener.in), update `Assumptions`, and write a 1-page Buy/Hold/Sell note. Until then, describe it as a "DCF model template".
- Projects 2 and 3 use a **synthetic** dataset (random but realistic, seed 42). Say "synthetic dataset" in your README and CV. Optionally repeat the analysis on a real one (Kaggle: Lending Club or German Credit).
- Do not list a skill on your CV until you can explain every line of it without looking.

## Running the SQL
- **DB Browser for SQLite** (free): open `data/credit_portfolio.db`, paste queries into "Execute SQL".
- **Or terminal:** `sqlite3 data/credit_portfolio.db < 2_SQL_Credit_Portfolio_Queries.sql`
- To rebuild from scratch: run `data/0_schema.sql`, then import the three CSVs.

## Sample findings from the synthetic data (verified by running the queries)
1. Portfolio: 1,800 loans, 943 borrowers, Rs 147.8 crore disbursed, average rate 13.0%.
2. Personal Loans default most (12.8%), Business Loans next (11.2%); Home Loans default least (1.8%) but make up about 57% of money disbursed.
3. Credit score below 600 defaults at 14.9%, about double the other bands (7-9%). Above 600 the pattern is not strictly rising, so score alone is not enough to price risk.
4. Delhi and Hyderabad show the highest city default rates (about 10.4%); Gurugram the lowest (6.9%).
5. 6.0% of the live book is 90+ days past due.

## CV bullets (use only after you have reviewed and can explain each)
- Built a 5-year DCF valuation model in Excel (CAPM-based WACC, FCFF projections, WACC x growth sensitivity grid, DuPont and ratio analysis) for [Company]; derived an intrinsic value of Rs [X] vs market price Rs [Y].
- Analysed a 1,800-loan synthetic credit portfolio (Rs 148 cr) in SQL using CTEs and window functions; found Personal Loans default at 12.8% vs 1.8% for Home Loans and sub-600 credit scores default at about 2x other bands.
- Designed a 2-page Power BI dashboard (DAX measures for default rate, PAR30, MoM growth) tracking portfolio risk by product, city and credit band.

## Your 2-minute walkthrough (practise out loud)
**Excel:** "I valued [Company] with a 5-year FCFF DCF. Revenue growth and margins come from its 5-year trend; WACC is about 11% using CAPM; terminal growth is 5%. Terminal value is about 77% of EV, so I tested a WACC and growth sensitivity grid. My view is [Buy/Hold/Sell] because..."
**SQL:** "I analysed loan defaults. Personal Loans are riskiest at 12.8% while Home Loans are 57% of the book but only 1.8% default. I used window functions for running totals and MoM growth, and NTILE to check whether credit score separates risk."
**Power BI:** "The dashboard shows disbursement trends, default rate by product and city, and a delinquency bucket view. The key insight is..."

## Questions interviewers may ask
- Why did you choose that WACC and terminal growth? What happens if growth is 6%?
- Why is terminal value such a large share of EV? Is that a problem?
- Difference between `RANK`, `DENSE_RANK` and `ROW_NUMBER`? Between `WHERE` and `HAVING`?
- Why did you use LEFT JOIN in the delinquency query?
- What is PAR30? Why use measures instead of calculated columns in DAX?

## Post on GitHub / LinkedIn
- GitHub repo with this folder, a short README per project, and dashboard screenshots.
- LinkedIn post: 1 insight + 1 screenshot + link per project.
