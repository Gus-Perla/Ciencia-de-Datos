{{ config(
    materialized='table'
) }}

SELECT

    LOCATIONID AS LOCATION_KEY,

    LOCATIONID,

    BOROUGH,

    ZONE,

    SERVICE_ZONE

FROM {{ ref('taxi_zone_lookup') }}
