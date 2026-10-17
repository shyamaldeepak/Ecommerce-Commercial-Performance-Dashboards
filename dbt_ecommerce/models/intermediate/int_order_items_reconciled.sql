WITH items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_total_payment,
        SUM(CASE WHEN payment_type = 'credit_card' THEN payment_value ELSE 0 END) AS credit_card_payment,
        SUM(CASE WHEN payment_type = 'boleto' THEN payment_value ELSE 0 END) AS boleto_payment,
        SUM(CASE WHEN payment_type = 'voucher' THEN payment_value ELSE 0 END) AS voucher_payment,
        SUM(CASE WHEN payment_type = 'debit_card' THEN payment_value ELSE 0 END) AS debit_card_payment,
        COUNT(payment_sequential) AS payment_splits_count
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

order_items_totals AS (
    SELECT
        order_id,
        COUNT(order_item_id) AS items_in_order_count,
        SUM(item_price) AS order_total_merchandise_value,
        SUM(item_freight) AS order_total_freight_value,
        SUM(item_total_value) AS order_total_items_value
    FROM items
    GROUP BY order_id
),

joined AS (
    SELECT
        -- Primary Grain: Line Item (order_id + order_item_id)
        items.order_id,
        items.order_item_id,
        items.product_id,
        items.seller_id,
        items.shipping_limit_date,
        items.item_price,
        items.item_freight,
        items.item_total_value,

        -- Order Context
        orders.customer_id,
        orders.order_status,
        orders.order_purchase_timestamp,
        orders.order_purchase_date,
        orders.order_year_month,
        orders.is_delivered,
        orders.delivery_lead_days,
        orders.is_delayed_delivery,

        -- Order Aggregate Context (Grain Aware)
        ord_tot.items_in_order_count,
        ord_tot.order_total_merchandise_value,
        ord_tot.order_total_freight_value,
        ord_tot.order_total_items_value,

        -- Payment Context (Pre-aggregated to prevent fan-out)
        COALESCE(pmt.order_total_payment, 0) AS order_total_payment,
        COALESCE(pmt.credit_card_payment, 0) AS credit_card_payment,
        COALESCE(pmt.boleto_payment, 0) AS boleto_payment,
        COALESCE(pmt.voucher_payment, 0) AS voucher_payment,
        COALESCE(pmt.debit_card_payment, 0) AS debit_card_payment,
        COALESCE(pmt.payment_splits_count, 0) AS payment_splits_count,

        -- Grain-Aware Proportional Payment Allocation per Item
        -- Ensures SUM(allocated_payment) at order level equals order_total_payment exactly
        CASE
            WHEN ord_tot.order_total_items_value = 0 THEN 0
            ELSE ROUND(
                (items.item_total_value / ord_tot.order_total_items_value) * COALESCE(pmt.order_total_payment, 0),
                2
            )
        END AS allocated_payment_value,

        -- Exact Reconciliation Delta Check
        ROUND(ord_tot.order_total_items_value - COALESCE(pmt.order_total_payment, 0), 2) AS order_reconciliation_delta,
        CASE
            WHEN ABS(ord_tot.order_total_items_value - COALESCE(pmt.order_total_payment, 0)) < 0.01 THEN 1
            ELSE 0
        END AS is_reconciled_to_cent

    FROM items
    INNER JOIN orders
        ON items.order_id = orders.order_id
    LEFT JOIN order_items_totals ord_tot
        ON items.order_id = ord_tot.order_id
    LEFT JOIN payments_agg pmt
        ON items.order_id = pmt.order_id
)

SELECT * FROM joined
