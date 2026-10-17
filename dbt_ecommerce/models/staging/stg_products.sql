WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_products') }}
),

transformed AS (
    SELECT
        TRIM(product_id) AS product_id,
        COALESCE(LOWER(TRIM(product_category_name)), 'unclassified') AS product_category_name,
        CAST(product_name_length AS INTEGER) AS product_name_length,
        CAST(product_description_length AS INTEGER) AS product_description_length,
        CAST(product_photos_qty AS INTEGER) AS product_photos_qty,
        CAST(product_weight_g AS INTEGER) AS product_weight_g,
        CAST(product_length_cm AS INTEGER) AS product_length_cm,
        CAST(product_height_cm AS INTEGER) AS product_height_cm,
        CAST(product_width_cm AS INTEGER) AS product_width_cm
    FROM source
)

SELECT * FROM transformed
