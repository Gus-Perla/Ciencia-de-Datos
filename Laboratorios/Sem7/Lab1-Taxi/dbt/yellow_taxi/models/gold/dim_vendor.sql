{{ config(
    materialized='table'
) }}

WITH vendors AS (

    SELECT DISTINCT VENDORID

    FROM {{ ref('stg_yellow_taxi') }}

    WHERE VENDORID IS NOT NULL

)

SELECT

    VENDORID AS VENDOR_KEY,

    VENDORID,

    CASE VENDORID
        WHEN 1 THEN 'Creative Mobile Technologies, LLC'
        WHEN 2 THEN 'Curb Mobility, LLC'
        WHEN 6 THEN 'Myle Technologies Inc'
        WHEN 7 THEN 'Helix'
        ELSE 'Other'
    END AS VENDOR_DESCRIPTION

FROM vendors