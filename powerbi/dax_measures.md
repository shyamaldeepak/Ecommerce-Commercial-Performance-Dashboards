# Power BI DAX Measures & Semantic Model Definitions

This document contains production-grade DAX formulas structured into standardized Measure Tables for the 4-page commercial reporting suite.

---

## 1. Core Financial & Revenue Measures (`_Revenue_Measures`)

```dax
// Total Gross Merchandise Value (excluding freight)
Total GMV = 
CALCULATE(
    SUM(mart_revenue[gross_merchandise_value]),
    mart_revenue[order_status] <> "canceled"
)

// Total Freight Revenue
Total Freight = 
CALCULATE(
    SUM(mart_revenue[freight_revenue]),
    mart_revenue[order_status] <> "canceled"
)

// Total Commercial Revenue (GMV + Freight)
Total Commercial Revenue = 
[Total GMV] + [Total Freight]

// Total Completed Orders Count
Total Orders = 
CALCULATE(
    DISTINCTCOUNT(mart_revenue[order_id]),
    mart_revenue[order_status] <> "canceled"
)

// Average Order Value (AOV)
AOV = 
DIVIDE(
    [Total Commercial Revenue],
    [Total Orders],
    0
)

// Month-over-Month Revenue Growth %
MoM Revenue Growth % = 
VAR CurrentMonthRev = [Total Commercial Revenue]
VAR PriorMonthRev = 
    CALCULATE(
        [Total Commercial Revenue],
        DATEADD('dim_date'[Date], -1, MONTH)
    )
RETURN
DIVIDE(
    CurrentMonthRev - PriorMonthRev,
    PriorMonthRev,
    0
)

// Financial Reconciliation Delta Check (Must equal 0.00)
Reconciliation Variance Check = 
SUM(mart_revenue[order_reconciliation_delta])

// Parity Status Flag
Parity Status KPI = 
IF(
    ABS([Reconciliation Variance Check]) < 0.01,
    "100% RECONCILED ($0.00 VARIANCE)",
    "AUDIT ALERT: VARIANCE DETECTED"
)
```

---

## 2. Customer Cohort & LTV Measures (`_Customer_Measures`)

```dax
// Total Unique Active Customers
Total Unique Customers = 
DISTINCTCOUNT(mart_customers[customer_unique_id])

// Repeat Buyers Count
Repeat Customers Count = 
CALCULATE(
    DISTINCTCOUNT(mart_customers[customer_unique_id]),
    mart_customers[is_repeat_customer] = 1
)

// Repeat Buyer Rate %
Repeat Buyer Rate % = 
DIVIDE(
    [Repeat Customers Count],
    [Total Unique Customers],
    0
)

// Average Customer Lifetime Value (LTV)
Average Customer LTV = 
AVERAGE(mart_customers[lifetime_total_spend])

// 90-Day Active Buyers Count
Active Buyers L90D = 
CALCULATE(
    DISTINCTCOUNT(mart_customers[customer_unique_id]),
    mart_customers[recency_days] <= 90
)

// Champions Segment Revenue Contribution %
Champions Revenue Share % = 
VAR ChampionsSpend = 
    CALCULATE(
        SUM(mart_customers[lifetime_total_spend]),
        mart_customers[rfm_customer_segment] = "Champions"
    )
VAR TotalSpend = SUM(mart_customers[lifetime_total_spend])
RETURN
DIVIDE(ChampionsSpend, TotalSpend, 0)
```

---

## 3. Merchandising & Product Measures (`_Product_Measures`)

```dax
// Total SKUs in Catalog
Total Catalog SKUs = 
DISTINCTCOUNT(mart_products[product_id])

// Total Units Sold
Total Units Sold = 
SUM(mart_products[total_units_sold])

// Catalog Average Selling Price (ASP)
Catalog ASP = 
DIVIDE(
    SUM(mart_products[total_merchandise_revenue]),
    [Total Units Sold],
    0
)

// Average Product Customer Rating
Overall Product Rating = 
AVERAGE(mart_products[avg_review_score])

// High Rated Product Share % (>= 4.0 Stars)
High Rated Products % = 
VAR HighRatedCount = 
    CALCULATE(
        COUNTROWS(mart_products),
        mart_products[avg_review_score] >= 4.0
    )
RETURN
DIVIDE(HighRatedCount, [Total Catalog SKUs], 0)
```

---

## 4. Merchant & Marketplace Fulfillment Measures (`_Seller_Measures`)

```dax
// Total Active Merchants
Active Sellers Count = 
DISTINCTCOUNT(mart_sellers[seller_id])

// Marketplace On-Time Delivery %
On-Time Delivery % = 
AVERAGE(mart_sellers[on_time_delivery_rate_pct])

// Average Delivery Lead Days
Avg Delivery Lead Days = 
AVERAGE(mart_sellers[avg_delivery_lead_days])

// Delayed Orders Count
Total Delayed Shipments = 
SUM(mart_sellers[delayed_orders_count])

// Elite Merchant GMV Contribution %
Elite Merchant GMV % = 
VAR EliteGMV = 
    CALCULATE(
        SUM(mart_sellers[total_merchandise_gmv]),
        mart_sellers[seller_performance_tier] = "Elite Merchant"
    )
VAR TotalGMV = SUM(mart_sellers[total_merchandise_gmv])
RETURN
DIVIDE(EliteGMV, TotalGMV, 0)
```
