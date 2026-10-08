# Analysts-lab-africa-finTrust-week-4
**SQL Refinements & Structural Improvements
1. NULL Handling in Window Functions: Query 1 (NTILE() OVER (ORDER BY
last_transaction_date ASC)) places customers with NULL dates (inactive/zero
transactions) at the top of the ordering window, distorting Recency scoring. The refined
query pushes NULL values to the tail via NULLS LAST and filters unlinked records before
ranking.
2. Division by Zero Protection: Queries 2, 3, 4, 5, and 8 rely on direct division for
percentage calculations (COUNT or SUM denominators). Wrapping all denominators in
NULLIF(..., 0) prevents division-by-zero crashes on zero-volume periods or filtered
subsets.
3. Data Type Standardization: In Query 4, CAST(transaction_datetime AS
TIMESTAMP) within DATE_TRUNC() can trigger redundant type casting across entire table
scans. The query has been refactored to optimize date grouping.
4. DRY (Don't Repeat Yourself) Code Efficiency: Query 7 duplicated a multi-line CASE
statement across both the SELECT and GROUP BY clauses. This is refactored using a CTE
to project the tier first, eliminating redundant logic evaluations.
5. Cross-Join Optimization: Query 6 performed a unfiltered CROSS JOIN across full
transaction tables before applying standard deviation logic. Standardizing this into a
scoped CTE improves execution speed.
Power BI
Section / Page Metric / Feature Current Value Verification Status
Page 1: Overview Total Transaction
Volume
₦560,477,354.85 Verified
Page 1: Overview Risk Review Trend 19.60 % Avg Verified
Page 2: Customers Active Customer
Ratio
91.13%
(1,367 Users)
Verified
Page 2: Customers Customer Detail
Table
1,500 Records Verified
Page 3: Transactions Total Failed Volume ₦ 24,825,751.10 Verified
Page 3: Risk Channel Failure
Rate
5.25% Verified
Final Validation Evidence Matrix
Finding Analytical Area
Pre-Validation
Premise
Post-Validation Corrective
Adjustment
1 Digital Volume
Gross volume
drives channel
success.
Replaced with Net Settled Volume
after finding 8.86% in un-settled
failures/reversals.
2 Customer CLV
High frequency =
High customer
value.
Updated CLV to RFM & Net Margin
after identifying high-frequency, lowyield users.
3
Revenue
Trajectory
Aggregated
quarterly growth is
stable.
Added Weekly/Monthly MoM
Tracking to catch mid-quarter
volume dips (₦2.3M drop in Feb).
4 Risk Distribution
Fraud occurs
uniformly across
cohorts.
Implemented Cohort-Specific Risk
Rules targeting recent digital
onboarding pipelines.
5
Channel
Efficiency
Speed and low fee
= High efficiency.
Adopted Risk-Adjusted Efficiency
Scorecard accounting for
chargebacks and reversals.**
