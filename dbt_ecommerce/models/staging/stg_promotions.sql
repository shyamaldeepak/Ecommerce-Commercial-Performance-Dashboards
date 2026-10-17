WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_promotions') }}
),

transformed AS (
    SELECT
        TRIM(promo_id) AS promo_id,
        UPPER(TRIM(promo_code)) AS promo_code,
        CAST(discount_pct AS DECIMAL(5, 2)) AS discount_percentage,
        TRIM(channel) AS acquisition_channel,
        CAST(valid_from AS DATE) AS valid_from_date,
        CAST(valid_to AS DATE) AS valid_to_date,
        CAST(is_active AS BOOLEAN) AS is_active
    FROM source
)

SELECT * FROM transformed
