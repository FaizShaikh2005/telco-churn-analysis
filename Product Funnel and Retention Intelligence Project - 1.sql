create database telco_project;

use telco_project;

CREATE TABLE telco_churn (
    customerID VARCHAR(20),
    gender VARCHAR(10),
    SeniorCitizen INT,
    Partner VARCHAR(5),
    Dependents VARCHAR(5),
    tenure INT,
    PhoneService VARCHAR(5),
    MultipleLines VARCHAR(20),
    InternetService VARCHAR(20),
    OnlineSecurity VARCHAR(20),
    OnlineBackup VARCHAR(20),
    DeviceProtection VARCHAR(20),
    TechSupport VARCHAR(20),
    StreamingTV VARCHAR(20),
    StreamingMovies VARCHAR(20),
    Contract VARCHAR(20),
    PaperlessBilling VARCHAR(5),
    PaymentMethod VARCHAR(30),
    MonthlyCharges DECIMAL(10,2),
    TotalCharges VARCHAR(20),
    Churn VARCHAR(5)
);

select * from telco_churn limit 5;

# 1. how many customers are active? how many are churned ? and whats the 
# churn rate pct ?
select 
	count(*) as total_customers,
    count(case when churn = 'Yes' then 1 end) as churned_customers,
    count(case when churn  = 'No' then 1 end) as active_customers,
	round(
    count(case when churn = 'Yes' then 1 end) * 100.0 / count(*),2
    ) as churn_rate_pct
from telco_churn;


-- the business has a 26.54% churn rate 1869 of the 7043 customers 
-- have churned these means roughly 1 in 4 customer is leaving 


-- "Does the type of contract a customer is on affect how likely they 
-- are to churn?And do higher-paying customers churn more or less?"

select
contract,
count(*) as total_customers,
count(case when churn = 'Yes' then 1 end) as churned_customers,
round(
	count(case when churn = 'Yes' then 1 end) * 100.0 / count(*) ,2 
) as churn_rate_pct,
round(avg(MonthlyCharges),2) as avg_monthly_charges,
avg(tenure) as avg_tenure_months
from telco_churn
group by contract
order by churn_rate_pct desc;


-- Month-to-month customers churn at 42.71% — nearly 1 in 2 customers leaves
-- Two-year contract customers churn at only 2.83% — almost nobody leaves
-- Despite similar monthly charges across all three (~₹61-66),
-- month-to-month customers stay only 18 months on average vs 56 months 
-- for two-year customers


-- The business insight: This isn't a pricing problem — 
-- all three contracts charge similar monthly amounts. It's a 
-- commitment problem. Customers who don't commit long-term churn at 
-- 15x the rate of those who do. The business should focus on 
-- converting month-to-month customers to annual contracts early.



-- Query 3
-- The Business Question

-- "When in the customer lifecycle does churn actually happen? 
-- Are we losing customers early, in the middle, 
-- or after long periods? Is there a 'danger zone' tenure window?"



SELECT 
    CASE 
        WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
        WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
        WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
        WHEN tenure BETWEEN 25 AND 48 THEN '4. 25-48 months'
        WHEN tenure > 48 THEN '5. 48+ months'
    END AS tenure_cohort,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) AS churned,
    ROUND(
        COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM telco_churn
GROUP BY tenure_cohort
ORDER BY tenure_cohort;


-- 52.94% of customers in their first 6 months churn — 
-- more than 1 in 2 new customers leaves before they even settle in
-- Churn drops consistently with every 
-- tenure bucket — 52% → 35% → 28% → 20% → 9%
-- Customers who survive past 48 months churn at only 9.51% — 
-- loyalty compounds over time
-- Interestingly, long-tenure customers (48+ months) pay ₹73.95/month 
-- on average vs ₹54.74 for new customers — retained customers are actually 
-- worth more

-- The business insight — this is your biggest finding so far:

-- "The business has a critical early-life churn problem. 
-- More than half of all new customers leave within 6 months. 
-- If the business can improve survival through the first year, 
-- the data suggests those customers become significantly more loyal AND
--  more valuable over time. The first 6 months is the danger zone."


-- Query 4
-- The Business Question

-- "Does adopting specific services (OnlineSecurity, TechSupport) 
-- make customers more likely to stay? Can we identify what 
-- 'activated' vs 'unactivated' customers look like in terms of churn?"


SELECT 
    OnlineSecurity,
    TechSupport,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM telco_churn
WHERE OnlineSecurity IN ('Yes', 'No')
  AND TechSupport IN ('Yes', 'No')
GROUP BY OnlineSecurity, TechSupport
ORDER BY churn_rate_pct DESC;

-- Customers with neither OnlineSecurity nor TechSupport churn at 48.96% — 
-- nearly 1 in 2 leaves
-- Customers with both services churn at only 9.01% — almost nobody leaves
-- Either service alone cuts churn roughly in half — from 49% down to ~21-22%
-- Customers with both services actually pay ₹81.47/month vs ₹74.19 — they're 
-- higher value AND more loyal

-- The business insight:

-- "Service adoption is the strongest behavioral predictor of retention 
-- we found. Customers who adopt neither OnlineSecurity nor TechSupport 
-- churn at 5x the rate of fully activated customers. This suggests the 
-- business should prioritize getting new customers onto these services
--  within their first 30 days 
-- — directly addressing the danger zone we identified in Query 3."


-- Query 5
-- The Business Question

-- "Among customers who haven't churned yet, which ones are the highest 
-- financial risk right now? 
-- Who should the retention team call first?"

WITH customer_risk AS (
    SELECT
        customerID,
        MonthlyCharges,
        Contract,
        tenure,
        CASE
            WHEN MonthlyCharges > 70
                 AND Contract = 'Month-to-month'
                 AND tenure < 12
            THEN 'HIGH RISK - High Value'
            WHEN MonthlyCharges BETWEEN 40 AND 70
                 AND Contract = 'Month-to-month'
                 AND tenure < 12
            THEN 'MEDIUM RISK'
            ELSE 'Lower Risk'
        END AS risk_segment
    FROM telco_churn
    WHERE Churn = 'No'
)

SELECT
    risk_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue_at_risk
FROM customer_risk
GROUP BY risk_segment
ORDER BY avg_monthly_charges DESC;

-- "248 active customers are HIGH RISK — they are on month-to-month contracts, 
-- less than 12 months old, and paying over ₹70/month. They represent ₹20,101 in
--  monthly recurring revenue. If they churn at the same rate as similar historical 
--  customers (42.71%), the business stands to lose approximately ₹8,600 every single 
--  month from this group alone."

-- That last number — ₹8,600 — you calculated it yourself:

-- 20,101 × 42.71% = ~₹8,583



-- "I analyzed a telecom dataset of 7,043 customers to understand why the business 
-- has a 26.54% churn rate and where the biggest risk lies.

-- First I looked at contract types and found month-to-month customers churn at 42.71% 
-- versus only 2.83% for two-year contracts — despite paying similar monthly charges. 
-- This told me it's a commitment problem, not a pricing problem.

-- Then I looked at tenure and found the danger zone — 52.94% of customers in their first 
-- 6 months churn. More than 1 in 2 new customers leaves before they settle in. 
-- But customers who survive past 48 months churn at only 9.51%, and they pay more on 
-- average.

-- I then investigated what behaviors separate churned from retained customers.
--  Customers with neither OnlineSecurity nor TechSupport churn at 48.96%. Customers 
--  with both churn at 9.01% — a 5x difference. This is the activation signal.

-- Finally I built a risk segmentation of current active customers and identified 
-- 248 high-value customers on month-to-month contracts in their first year. 
-- They represent ₹20,101 in monthly revenue. At the historical churn rate for this profile
-- , the business is at risk of losing ~₹8,600 every month from this group alone.

-- My recommendation: the retention team should prioritize these 248 customers immediately
--  — offer them an incentive to switch to an annual contract and get them onto 
--  OnlineSecurity or TechSupport within 30 days."





-- Query 6
-- The Business Question
-- "What does the churn rate look like across different payment methods? 
-- Are customers who pay automatically
--  (set-and-forget) more loyal than those who manually pay every month?"


select
PaymentMethod,
count(*) as total_customers,
count(case when churn = 'Yes' then 1 end) as churned_customers,
count(case when churn = 'Yes' then 1 end) * 100.0 / 
count(*) as  churn_rate_pct,
round(avg(MonthlyCharges),2) as avg_monthly_charges,
round(avg(tenure),2) as average_tenure
from telco_churn
group by PaymentMethod
order by churn_rate_pct desc;

-- Electronic check customers churn at 45.28% — nearly as bad as 
-- month-to-month contracts
-- The three other methods all cluster between 15-19% churn — dramatically 
-- lower
-- Both automatic payment methods (bank transfer + credit card) have average
--  tenure 
-- of 43+ months vs only 25 months for electronic check
-- Electronic check customers also pay more on average (₹76.26) — so they're
--  high value AND high risk


-- "Electronic check is not just a payment preference — 
-- it's a churn signal. Customers paying by electronic check churn at 
-- 3x the rate of automatic payment customers. This likely overlaps heavily 
-- with the month-to-month, low-tenure danger zone we already identified. 
-- The business should consider incentivizing a switch to 
-- automatic payments as part of the early retention strategy."


-- Query 7 — Window Functions (First Time)
-- The Business Question

-- "Within each contract type, how does a customer's 
-- monthly charge compare to the average for their group? 
-- Who is overpaying relative to their peers — 
-- and are overpaying customers more likely to churn?"



WITH customer_pricing AS (
    SELECT
        customerID,
        Contract,
        MonthlyCharges,
        Churn,
        ROUND(AVG(MonthlyCharges) OVER (PARTITION BY Contract), 2) AS avg_charges_by_contract,
        ROUND(MonthlyCharges - AVG(MonthlyCharges) OVER (PARTITION BY Contract), 2) AS charge_diff,
        CASE
            WHEN MonthlyCharges > AVG(MonthlyCharges) OVER (PARTITION BY Contract) + 5
            THEN 'Above Average'
            WHEN MonthlyCharges < AVG(MonthlyCharges) OVER (PARTITION BY Contract) - 5
            THEN 'Below Average'
            ELSE 'Average'
        END AS price_position
    FROM telco_churn
)

SELECT
    Contract,
    price_position,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) AS churned,
    ROUND(
        COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customer_pricing
GROUP BY Contract, price_position
ORDER BY Contract, churn_rate_pct DESC;




-- What This Result Is Telling You

-- Write these in your Notepad:

-- Within month-to-month contracts, above-average payers churn at 52.66% vs 29.99% for below-average payers — customers paying more than their peers are nearly twice as likely to leave
-- A two-year above-average payer churns at only 4.55% — same price position, completely different churn story. Contract type dominates everything
-- One-year below-average payers churn at 4.65% — nearly as safe as two-year customers entirely
-- The most dangerous single cell in this entire table: month-to-month + above average price — 1,971 customers, 52.66% churn, paying ₹88.60/month average

-- The business insight:

-- "Price sensitivity is real but only within the month-to-month segment. High-paying month-to-month customers churn at 52.66% — they are getting the least value for the most money with zero commitment locking them in. This group should be the first target for contract upgrade offers, potentially with a loyalty discount to reduce their charges while securing a longer commitment."



-- Query 8 — Advanced CTE + Running Totals
-- The Business Question

-- "How much of the total churned revenue is concentrated in a 
-- small number of customers? If we ranked all churned customers 
-- by what they were paying, what percentage 
-- of total lost revenue comes from the top 20%?"



WITH ranked_churners AS (
    SELECT
        customerID,
        MonthlyCharges,
        ROW_NUMBER() OVER (ORDER BY MonthlyCharges DESC) AS charge_rank,
        SUM(MonthlyCharges) OVER (
            ORDER BY MonthlyCharges DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_revenue,
        COUNT(*) OVER () AS total_churners,
        SUM(MonthlyCharges) OVER () AS total_churned_revenue
    FROM telco_churn
    WHERE Churn = 'Yes'
),

percentile_calc AS (
    SELECT
        customerID,
        MonthlyCharges,
        charge_rank,
        running_revenue,
        total_churners,
        total_churned_revenue,
        ROUND(charge_rank * 1.0 / total_churners, 4) AS percentile_position,
        ROUND(running_revenue * 100.0 / total_churned_revenue, 2) AS cumulative_revenue_pct
    FROM ranked_churners
)

SELECT
    CASE
        WHEN percentile_position <= 0.10 THEN '1. Top 10% of churners'
        WHEN percentile_position <= 0.20 THEN '2. Top 10-20% of churners'
        WHEN percentile_position <= 0.50 THEN '3. Top 20-50% of churners'
        ELSE '4. Bottom 50% of churners'
    END AS churner_band,
    COUNT(*) AS customer_count,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue,
    ROUND(SUM(MonthlyCharges) * 100.0 / MAX(total_churned_revenue), 2) AS pct_of_total_churned_revenue
FROM percentile_calc
GROUP BY churner_band
ORDER BY churner_band;

-- What This Result Is Telling You

-- Write this in your Notepad:

-- The top 20% of churners account for 27.58% of total churned revenue (14.24% + 13.34%)
-- The top 50% of churners account for 62.95% of total churned revenue
-- Top 10% churners pay ₹106.52/month average vs ₹55.13 for the bottom 50% — nearly double
-- This is not a pure 80/20 — churn revenue is more evenly distributed than typical Pareto, meaning even mid-value churners matter

-- The business insight:

-- "Unlike a classic 80/20 distribution, churned revenue is spread across the customer base — the bottom 50% of churners still represent 37% of lost revenue. This means a broad retention strategy targeting all at-risk customers is more appropriate than focusing exclusively on high-value churners. However, the top 10% — 186 customers paying ₹106/month — should still get priority white-glove treatment."


-- Query 9 — The Final SQL Query
-- The Business Question

-- "Can we build a single complete customer profile that combines everything we've learned — contract type, tenure cohort, service adoption, payment method, price position, and risk level — into one master summary table? What does the breakdown of our customer base look like when all dimensions are combined?"



WITH customer_profile AS (

    SELECT
        customerID,
        Contract,
        tenure,
        OnlineSecurity,
        TechSupport,
        PaymentMethod,
        MonthlyCharges,
        Churn,

        -- 1. Tenure Cohort
        CASE
            WHEN tenure < 12 THEN '0-11 Months'
            WHEN tenure < 24 THEN '12-23 Months'
            WHEN tenure < 48 THEN '24-47 Months'
            ELSE '48+ Months'
        END AS tenure_cohort,

        -- 2. Service Adoption
        CASE
            WHEN OnlineSecurity = 'Yes'
                 AND TechSupport = 'Yes'
                THEN 'Both Services'

            WHEN OnlineSecurity = 'Yes'
                 OR TechSupport = 'Yes'
                THEN 'One Service'

            ELSE 'No Services'
        END AS service_adoption,

        -- 3. Payment Type
        CASE
            WHEN PaymentMethod IN (
                'Bank transfer (automatic)',
                'Credit card (automatic)'
            )
                THEN 'Automatic'
            ELSE 'Manual'
        END AS payment_type,

        -- 4. Average Monthly Charge within Contract Group
        AVG(MonthlyCharges) OVER (
            PARTITION BY Contract
        ) AS contract_avg_charges

    FROM telco_churn
),

profile_with_price AS (

    SELECT
        *,
        
        -- 5. Price Position
        CASE
            WHEN MonthlyCharges > contract_avg_charges
                THEN 'Above Average'
            WHEN MonthlyCharges < contract_avg_charges
                THEN 'Below Average'
            ELSE 'Average'
        END AS price_position

    FROM customer_profile
),

risk_profile AS (

    SELECT
        *,
        
        -- 6. Risk Score
        (
            CASE
                WHEN Contract = 'Month-to-month' THEN 3
                ELSE 0
            END

            +

            CASE
                WHEN tenure < 12 THEN 2
                ELSE 0
            END

            +

            CASE
                WHEN service_adoption = 'No Services' THEN 2
                ELSE 0
            END

            +

            CASE
                WHEN payment_type = 'Manual' THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN price_position = 'Above Average' THEN 1
                ELSE 0
            END
        ) AS risk_score

    FROM profile_with_price
),

final_profile AS (

    SELECT
        *,
        
        -- 7. Risk Level
        CASE
            WHEN risk_score >= 7 THEN 'CRITICAL'
            WHEN risk_score >= 5 THEN 'HIGH'
            WHEN risk_score >= 3 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_level

    FROM risk_profile
)

-- 8. Final Business Summary
SELECT
    risk_level,
    COUNT(*) AS customer_count,

    ROUND(
        100.0 * SUM(
            CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS churn_rate,

    ROUND(
        AVG(MonthlyCharges),
        2
    ) AS avg_monthly_charges,

    ROUND(
        SUM(MonthlyCharges),
        2
    ) AS total_monthly_revenue

FROM final_profile

GROUP BY risk_level

ORDER BY
    CASE risk_level
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
    END;


-- What This Result Is Telling You

-- Write this in your Notepad — this is your single most powerful finding:

-- CRITICAL risk customers churn at 54.28% — more than 1 in 2 is leaving
-- LOW risk customers churn at 6.27% — nearly nobody leaves
-- The risk model works — churn rate drops perfectly from 54% → 28% → 13% → 6% across bands. No anomalies. Clean signal.
-- CRITICAL segment represents ₹141,955/month in revenue — at 54.28% churn that's ~₹77,059 leaving every month
-- Even HIGH risk at ₹83,714/month with 28.71% churn = ~₹24,035/month at risk

-- The business insight — this is your closing argument:

-- "The risk scoring model cleanly separates the customer base into four distinct churn profiles. The CRITICAL segment alone — 2,161 customers — represents over ₹77,000 in monthly revenue walking out the door. A targeted retention intervention on just this segment, even if it saves 20% of them, would recover ~₹15,400 per month or ~₹1,84,800 annually."

WITH customer_profile AS (
    SELECT
        customerID,
        Contract,
        tenure,
        MonthlyCharges,
        Churn,
        OnlineSecurity,
        TechSupport,
        PaymentMethod,
        CASE
            WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
            WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
            WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
            WHEN tenure BETWEEN 25 AND 48 THEN '4. 25-48 months'
            ELSE '5. 48+ months'
        END AS tenure_cohort,
        CASE
            WHEN OnlineSecurity = 'Yes' AND TechSupport = 'Yes' THEN 'Both Services'
            WHEN OnlineSecurity = 'Yes' OR TechSupport = 'Yes' THEN 'One Service'
            ELSE 'No Services'
        END AS service_adoption,
        CASE
            WHEN PaymentMethod IN ('Bank transfer (automatic)', 'Credit card (automatic)')
            THEN 'Automatic'
            ELSE 'Manual'
        END AS payment_type,
        AVG(MonthlyCharges) OVER (PARTITION BY Contract) AS contract_avg_charges
    FROM telco_churn
),

risk_scored AS (
    SELECT
        *,
        CASE WHEN MonthlyCharges > contract_avg_charges + 5 THEN 'Above Average'
             WHEN MonthlyCharges < contract_avg_charges - 5 THEN 'Below Average'
             ELSE 'Average'
        END AS price_position,
        (
            CASE WHEN Contract = 'Month-to-month' THEN 3 ELSE 0 END +
            CASE WHEN tenure < 12 THEN 2 ELSE 0 END +
            CASE WHEN service_adoption = 'No Services' THEN 2 ELSE 0 END +
            CASE WHEN PaymentMethod IN ('Electronic check', 'Mailed check') THEN 1 ELSE 0 END +
            CASE WHEN MonthlyCharges > contract_avg_charges + 5 THEN 1 ELSE 0 END
        ) AS risk_score
    FROM customer_profile
)

SELECT
    CASE
        WHEN risk_score >= 7 THEN 'CRITICAL'
        WHEN risk_score >= 5 THEN 'HIGH'
        WHEN risk_score >= 3 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_level,
    COUNT(*) AS customer_count,
    ROUND(COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS churn_rate,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue
FROM risk_scored
GROUP BY risk_level
ORDER BY MIN(risk_score) DESC;




















