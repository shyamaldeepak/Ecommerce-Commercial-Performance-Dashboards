# 4-Page Power BI Commercial Performance Report Specification

This specification documents the architecture, data model bindings, visual components, interactive slicers, and layout specifications for the executive Power BI reporting suite connected to the four Snowflake/DuckDB data marts.

---

## Data Model Architecture (Star Schema)
```
          [dim_date]           [dim_geography]
              |                       |
              +-----------+-----------+
                          |
             +------------v-------------+
             |       mart_revenue       |  (Fact Table: Orders Grain)
             +------------+-------------+
                          |
       +------------------+------------------+
       |                                     |
+------v-------+                      +------v-------+
|mart_customers|                      |mart_sellers  | (Dimension/Fact)
+--------------+                      +--------------+
       |
+------v-------+
|mart_products |
+--------------+
```

---

## Page 1: Commercial Revenue & Order Performance

### Core Purpose
High-level executive overview of gross revenue, freight income, payment tender mix, and financial reconciliation health.

### KPI Cards (Top Banner)
1. **Total Gross Merchandise Value (GMV):** `[Total GMV]` (e.g., `$15.2M`)
2. **Freight Revenue:** `[Total Freight]` (e.g., `$2.25M`)
3. **Total Commercial Revenue:** `[Total Commercial Revenue]` (GMV + Freight)
4. **Average Order Value (AOV):** `[AOV]` (e.g., `$175.40`)
5. **Reconciliation Parity Status:** `100.00% Reconciled ($0.00 delta)`

### Visual Layout
- **Visual 1 (Top Left - Column & Line):** Monthly GMV and Freight Trend with MoM Growth %.
  - X-Axis: `order_year_month`
  - Column Y-Axis: `Gross Merchandise Value`, `Freight Revenue`
  - Line Y-Axis: `MoM Revenue Growth %`
- **Visual 2 (Top Right - Donut Chart):** Revenue Distribution by Payment Method.
  - Legend: `primary_payment_method` (Credit Card, Boleto, Voucher, Split)
  - Values: `[Total Commercial Revenue]`
- **Visual 3 (Bottom Left - Stacked Bar Chart):** Order Fulfillment Status Distribution.
  - Y-Axis: `order_status` (Delivered, Shipped, Canceled)
  - X-Axis: `Order Count`, `Total GMV`
- **Visual 4 (Bottom Right - Financial Audit Table):** Monthly Reconciliation Parity Verification.
  - Columns: `Month`, `GMV`, `Freight`, `Expected Cash`, `Collected Cash`, `Delta ($)` (Asserts $0.00)

---

## Page 2: Customer Cohorts & Lifetime Value (LTV)

### Core Purpose
Deep-dive into customer retention, repeat purchasing patterns, cohort revenue decay, and RFM segmentation.

### KPI Cards (Top Banner)
1. **Total Unique Customers:** `[Total Unique Customers]` (e.g., `85,000`)
2. **Repeat Buyer Rate:** `[Repeat Buyer Rate %]` (e.g., `11.8%`)
3. **Average Lifetime Spend:** `[Average Customer LTV]`
4. **90-Day Active Buyers:** `[Active Buyers L90D]`

### Visual Layout
- **Visual 1 (Top Left - Tree Map):** RFM Customer Segmentation Matrix.
  - Group: `rfm_customer_segment` (Champions, Loyal Customers, New Customers, At Risk Repeaters, Hibernating)
  - Values: `[Total Customers Count]`
  - Tooltips: `[Segment Revenue Share]`, `[Avg LTV]`
- **Visual 2 (Top Right - Cohort Matrix):** Monthly Customer Cohort Spend Heatmap.
  - Rows: `first_order_cohort_month`
  - Columns: `order_year_month`
  - Values: `[Cohort Cumulative Spend]`
- **Visual 3 (Bottom Left - Filled Choropleth Map):** Customer Geographic Distribution.
  - Location: `primary_state`
  - Color Saturation: `[Total Customer Spend]`
- **Visual 4 (Bottom Right - Clustered Column Chart):** Spend Tier Composition.
  - X-Axis: `spend_tier` (Tier 1 >$1k, Tier 2 $500-$999, Tier 3 $200-$499, Tier 4 <$200)
  - Y-Axis: `Customer Count`, `Total GMV Generated`

---

## Page 3: Product & Category Commercial Performance

### Core Purpose
Merchandising intelligence, category share of wallet, SKU price elasticity, and customer satisfaction ratings.

### KPI Cards (Top Banner)
1. **Active Catalog SKUs:** `[Total SKUs]` (e.g., `32,951`)
2. **Top Category Revenue:** `[Top Category GMV]`
3. **Average Selling Price (ASP):** `[Catalog ASP]`
4. **Average Catalog Rating:** `[Overall Product Rating]` (e.g., `4.12 / 5.0`)

### Visual Layout
- **Visual 1 (Top Left - Horizontal Bar Chart):** Top 10 Product Categories by GMV.
  - Y-Axis: `product_category_name`
  - X-Axis: `[Total Merchandise Revenue]`
  - Data Labels: Value & % Share of Total
- **Visual 2 (Top Right - Scatter Plot):** Category Margin & Volume Positioning.
  - X-Axis: `Units Sold`
  - Y-Axis: `Average Unit Selling Price (ASP)`
  - Bubble Size: `Total GMV`
  - Color: `Average Review Score`
- **Visual 3 (Bottom Table - SKU Leaderboard):** Product Performance Drilldown.
  - Columns: `Rank in Category`, `Product ID`, `Category`, `Units Sold`, `Total GMV`, `Avg Price`, `Review Score`
- **Visual 4 (Bottom Right - Clustered Bar):** Category Customer Review Score Distribution.
  - Y-Axis: `product_category_name`
  - X-Axis: `Avg Review Score` (1.0 to 5.0)

---

## Page 4: Seller Operations & Marketplace Fulfillment

### Core Purpose
Vendor performance monitoring, fulfillment SLA compliance, delivery delay risk, and merchant tiering.

### KPI Cards (Top Banner)
1. **Active Merchants:** `[Active Sellers Count]` (e.g., `3,095`)
2. **Marketplace On-Time Delivery Rate:** `[On-Time Delivery %]` (e.g., `92.4%`)
3. **Average Delivery Lead Time:** `[Avg Delivery Lead Days]` (e.g., `12.1 Days`)
4. **Elite Merchant Share of GMV:** `[Elite Merchant GMV %]`

### Visual Layout
- **Visual 1 (Top Left - Quadrant Scatter Plot):** Merchant Performance Quadrant.
  - X-Axis: `On-Time Delivery Rate %`
  - Y-Axis: `Total Merchandise GMV`
  - Quadrant Reference Lines: X=90%, Y=$10k
  - Quadrant 1 (Top Right): Elite High-Volume Merchants
  - Quadrant 4 (Bottom Left): At-Risk Delayed Merchants
- **Visual 2 (Top Right - Donut Chart):** Merchant Distribution by Tier.
  - Legend: `seller_performance_tier` (Elite, Established, Standard, Watchlist)
  - Values: `[Merchant Count]`, `[GMV Contribution]`
- **Visual 3 (Bottom Left - Bar Chart):** Delivery Lead Time vs SLA by Customer Destination State.
  - X-Axis: `State`
  - Bars: `Average Actual Delivery Days` vs `Average Estimated Delivery Days`
- **Visual 4 (Bottom Right - Table):** Merchant SLA Scorecard.
  - Columns: `Seller ID`, `State`, `Orders Fulfilled`, `Total GMV`, `Avg Delivery Days`, `Delayed Orders`, `On-Time %`, `Review Score`, `Tier`
