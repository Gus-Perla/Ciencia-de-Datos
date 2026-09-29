{{ config(
    materialized='table'
) }}

WITH rates AS (

    SELECT DISTINCT
        RATECODEID

    FROM {{ ref('stg_yellow_taxi') }}

)

SELECT

    RATECODEID AS RATE_KEY,

    RATECODEID,

    CASE RATECODEID
        WHEN 1 THEN 'Standard rate'
        WHEN 2 THEN 'JFK'
        WHEN 3 THEN 'Newark'
        WHEN 4 THEN 'Nassau or Westchester'
        WHEN 5 THEN 'Negotiated fare'
        WHEN 6 THEN 'Group ride'
        WHEN 99 THEN 'Null/unknown'
        ELSE 'Other'
    END AS RATE_DESCRIPTION

FROM rates