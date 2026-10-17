WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_customers') }}
),

transformed AS (
    SELECT
        TRIM(customer_id) AS customer_id,
        TRIM(customer_unique_id) AS customer_unique_id,
        TRIM(customer_zip_code) AS customer_zip_code,
        LOWER(TRIM(customer_city)) AS customer_city,
        UPPER(TRIM(customer_state)) AS customer_state,
        CAST(created_at AS TIMESTAMP) AS customer_created_at
    FROM source
)

SELECT * FROM transformed
