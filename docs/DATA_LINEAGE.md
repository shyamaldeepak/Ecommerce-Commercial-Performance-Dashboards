# E-Commerce Data Pipeline Architecture & Data Lineage

This document illustrates the end-to-end data lineage across the 8 raw source tables (550,759 records), 8 staging views, 3 intermediate models, and 4 Snowflake/DuckDB analytical marts feeding the 4-page Power BI executive dashboard.

---

## 1. End-to-End Data Lineage Diagram (Mermaid)

```mermaid
flowchart TD
    subgraph Raw_Sources ["8 Raw Source Tables (550,759 Records)"]
        R1[raw_customers<br/>96,096 rows]
        R2[raw_orders<br/>99,441 rows]
        R3[raw_order_items<br/>112,650 rows]
        R4[raw_order_payments<br/>103,886 rows]
        R5[raw_order_reviews<br/>99,224 rows]
        R6[raw_products<br/>32,951 rows]
        R7[raw_sellers<br/>3,095 rows]
        R8[raw_promotions<br/>3,416 rows]
    end

    subgraph Staging_Views ["8 Staging Models (1:1 Schema Cleaning)"]
        S1[stg_customers]
        S2[stg_orders]
        S3[stg_order_items]
        S4[stg_order_payments]
        S5[stg_order_reviews]
        S6[stg_products]
        S7[stg_sellers]
        S8[stg_promotions]
    end

    subgraph Intermediate_Models ["3 Intermediate Models (Grain-Aware Joins & Aggregations)"]
        I1["int_order_items_reconciled<br/>(Grain: order_id + order_item_id)<br/>• Pre-aggregates payments to avoid fan-out<br/>• Allocates payment proportionally<br/>• Parity check: Delta = $0.00"]
        I2["int_customer_orders_summary<br/>(Grain: customer_unique_id)<br/>• RFM segmentation<br/>• Cohort month & LTV"]
        I3["int_seller_performance_summary<br/>(Grain: seller_id)<br/>• Lead time & on-time SLA %<br/>• Seller GMV & tiering"]
    end

    subgraph Data_Marts ["4 Snowflake / DuckDB Production Marts"]
        M1["mart_revenue<br/>(Power BI Page 1: Revenue)<br/>Grain: order_id"]
        M2["mart_customers<br/>(Power BI Page 2: Customers)<br/>Grain: customer_unique_id"]
        M3["mart_products<br/>(Power BI Page 3: Products)<br/>Grain: product_id"]
        M4["mart_sellers<br/>(Power BI Page 4: Sellers)<br/>Grain: seller_id"]
    end

    subgraph BI_Reporting ["4-Page Power BI Commercial Report"]
        P1["Page 1: Commercial Revenue<br/>GMV, Freight, Payment Breakdown, AOV"]
        P2["Page 2: Customer Cohorts & LTV<br/>RFM Segments, Repeat Rates, Retention"]
        P3["Page 3: Product Category Insights<br/>Top SKUs, Category Margin, Review Ratings"]
        P4["Page 4: Merchant & Seller Operations<br/>GMV Rank, Fulfillment SLA, On-Time %"]
    end

    %% Lineage Connections
    R1 --> S1
    R2 --> S2
    R3 --> S3
    R4 --> S4
    R5 --> S5
    R6 --> S6
    R7 --> S7
    R8 --> S8

    S2 --> I1
    S3 --> I1
    S4 --> I1

    S1 --> I2
    S2 --> I2
    I1 --> I2

    S7 --> I3
    I1 --> I3
    S5 --> I3

    I1 --> M1
    I2 --> M2
    S6 --> M3
    S3 --> M3
    S2 --> M3
    S5 --> M3
    I3 --> M4

    M1 --> P1
    M2 --> P2
    M3 --> P3
    M4 --> P4
```

---

## 2. Grain Shift & Transformation Logic Summary

| Transition Step | Upstream Grain | Downstream Grain | Logic Applied | Key Risk Mitigated |
| :--- | :--- | :--- | :--- | :--- |
| **Raw $\to$ Staging** | Source raw records | Typed, normalized view | Type casting, timestamp parsing, standardized casing, whitespace stripping. | Dirty datatypes, malformed timestamps. |
| **Staging $\to$ `int_order_items_reconciled`** | Order items & Split payments | Single order item | Pre-aggregates payments to `order_id` in CTE; joins to items; allocates cash proportionally by item value share. | **Cartesian Fan-Out:** Prevents multi-item $\times$ multi-payment cross product duplication of revenue. |
| **Staging + Int $\to$ `int_customer_orders_summary`** | Individual orders | Unique customer individual (`customer_unique_id`) | Aggregates all orders by individual; extracts first/last order dates, lifetime spend, and computes RFM segmentation. | Miscounting repeat buyers who have different session `customer_id`s. |
| **Staging + Int $\to$ `int_seller_performance_summary`** | Line items & Reviews | Single seller merchant (`seller_id`) | Aggregates GMV, calculates delivery days vs estimated date SLA, computes on-time % and assigns performance tier. | Inaccurate SLA calculation across multiple items in an order. |
| **Intermediate $\to$ 4 Marts** | Pre-calculated summaries | Clean star-schema dimensions & facts | Final business ranking, categorization, and presentation metrics. | Heavy aggregations at BI visualization time. |
