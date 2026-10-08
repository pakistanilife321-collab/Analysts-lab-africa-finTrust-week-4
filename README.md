# Analysts-lab-africa-finTrust-week-4
# FinTrust Digital Bank — Financial Intelligence & Analytics Solution

![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-yellow?style=for-the-badge&logo=powerbi)
![PostgreSQL](https://img.shields.io/badge/SQL-PostgreSQL-blue?style=for-the-badge&logo=postgresql)
![Python](https://img.shields.io/badge/Python-3.10+-green?style=for-the-badge&logo=python)

## Executive Summary
This repository contains the end-to-end analytical solution developed for **FinTrust Digital Bank** as part of the **AnalystLab Africa Experience Lab Internship Programme** (Week 4 Final Deliverable).

The primary goal of this project was to diagnose revenue leakage, evaluate payment channel reliability, analyze customer lifetime value (CLV), and detect synthetic fraud risk across 12,000 transactions valued at **₦560.48 Million**.

---

---

## 🛠️ Tech Stack & Key Methods Used
* **SQL (PostgreSQL / MySQL 8.0+):** Common Table Expressions (CTEs), `NTILE()` and `LAG()` window functions, conditional aggregations, `NULLIF` division protection, and relational `JOIN` logic.
* **Power BI Desktop:** DAX time-intelligence metrics, Star Schema data modeling, custom KPI cards, cross-filtering matrices, and interactive slicers.
* **Python (Pandas, NumPy, Seaborn):** Exploratory Data Analysis (EDA), K-NN missing data imputation, Z-Score outlier detection (Z > 3.0), and validation modeling.

---

## 📊 Key Executive Metrics
* **Total Gross Transaction Volume:** ₦560,477,354.85
* **Total Transactions Processed:** 12,000
* **Total Active Customers:** 1,500
* **Average Transaction Value:** ₦46,706.45
* **Overall Transaction Success Rate:** 90.47%
* **Channel Failure Rate:** 5.25% (₦24.83M in failed volume)
* **Risk Review Rate:** 19.60% (2,352 flagged transactions)

---

## 💡 Key Business Insights

### 1. Digital Channel Failure Rates & Net Settled Volume
* **Finding:** High gross volume on mobile and USSD channels conceals gateway switch instabilities.
* **Evidence:** Out of ₦560.48M in gross volume, ₦24.83M failed (5.25% failure rate), with Mobile App accounting for 296 failed attempts (₦13.09M).
* **Business Meaning:** Evaluating channels purely on gross volume obscures revenue leakage and erodes customer trust.
* **Recommended Action:** Shift internal KPIs to **Net Settled Volume** and re-negotiate Telco switch SLAs.

### 2. Revenue Concentration & Dynamic RFM Segmentation
* **Finding:** Everyday customers generate 46.6% of overall volume (₦261.46M), while 7.13% of registered accounts are dormant.
* **Evidence:** SQL RFM windowing revealed that static demographic models misallocated retention spending to high-frequency but unprofitable transactors.
* **Business Meaning:** Traditional Customer Lifetime Value (CLV) models fail to protect high-margin Everyday and Premium cohorts.
* **Recommended Action:** Implement an **RFM & Net Margin CLV** framework with automated re-engagement triggers for dormant users.

---

## 🔬 Analytical Validation Evidence Matrix

| Finding # | Area | Pre-Validation Premise | Post-Validation Correction |
| :---: | :--- | :--- | :--- |
| **1** | **Digital Volume** | Gross volume drives channel success. | Replaced with **Net Settled Volume** after identifying 8.86% in un-settled failures/reversals. |
| **2** | **Customer CLV** | High frequency = High customer value. | Updated CLV to **RFM & Net Margin** after identifying high-frequency, low-yield users. |
| **3** | **Risk Distribution** | Fraud occurs uniformly across cohorts. | Implemented **Cohort-Specific Risk Rules** targeting recent digital onboarding pipelines. |

---

## 🚀 How to Run the SQL Scripts
1. Import `customers` and `transactions` tables into PostgreSQL / MySQL database.
2. Open `SQL_Scripts/fintrust_week4_final_analysis.sql` in pgAdmin, DBeaver, or DataGrip.
3. Execute queries 1 through 8 sequentially to generate the RFM metrics, channel failure tables, and Z-score risk flags.

---

## 🧑‍💻 Author
* **Name:** Laraib Fatima
* **Role:** Data Analyst / AnalystLab Africa Intern
