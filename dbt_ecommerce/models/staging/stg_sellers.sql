WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_sellers') }}
),

transformed AS (
    SELECT
        TRIM(seller_id) AS seller_id,
        TRIM(seller_zip_code_prefix) AS seller_zip_code,
        LOWER(TRIM(seller_city)) AS seller_city,
        UPPER(TRIM(seller_state)) AS seller_state
    FROM source
)

SELECT * FROM transformed
