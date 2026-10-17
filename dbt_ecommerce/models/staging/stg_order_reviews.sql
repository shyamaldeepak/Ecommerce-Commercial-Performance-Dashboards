WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_order_reviews') }}
),

transformed AS (
    SELECT
        TRIM(review_id) AS review_id,
        TRIM(order_id) AS order_id,
        CAST(review_score AS INTEGER) AS review_score,
        TRIM(review_comment_title) AS review_comment_title,
        CAST(review_creation_date AS DATE) AS review_creation_date,
        CAST(review_answer_timestamp AS TIMESTAMP) AS review_answer_timestamp
    FROM source
)

SELECT * FROM transformed
