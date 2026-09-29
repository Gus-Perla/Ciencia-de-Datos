{{ config(
    materialized='table'
) }}

WITH payments AS (

    SELECT DISTINCT
        PAYMENT_TYPE

    FROM {{ ref('stg_yellow_taxi') }}

)

SELECT

    PAYMENT_TYPE AS PAYMENT_KEY,

    PAYMENT_TYPE,

    CASE PAYMENT_TYPE
        WHEN 0 THEN 'Flex Fare'
        WHEN 1 THEN 'Credit card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        WHEN 6 THEN 'Voided trip'
        ELSE 'Other'
    END AS PAYMENT_DESCRIPTION

FROM payments