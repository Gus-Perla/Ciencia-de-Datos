{{ config(
    materialized='table'
) }}

WITH trips AS (

    SELECT
        TRIP_ID,

        CAST(TPEP_PICKUP_DATETIME AS DATE) AS PICKUP_DATE,
        CAST(TPEP_PICKUP_DATETIME AS TIME) AS PICKUP_TIME,

        PULOCATIONID,
        DOLOCATIONID,

        PAYMENT_TYPE,
        RATECODEID,
        VENDORID,

        PASSENGER_COUNT,
        TRIP_DISTANCE,
        TRIP_DURATION_MINUTES,

        FARE_AMOUNT,
        EXTRA,
        MTA_TAX,
        TIP_AMOUNT,
        TOLLS_AMOUNT,
        IMPROVEMENT_SURCHARGE,
        CONGESTION_SURCHARGE,
        AIRPORT_FEE,
        CBD_CONGESTION_FEE,
        TOTAL_AMOUNT,

        _SOURCE_FILE,
        _SOURCE_YEAR,
        _SOURCE_MONTH,
        _LOADED_AT

    FROM {{ ref('stg_yellow_taxi') }}

)

SELECT

    t.TRIP_ID,

    d.DATE_KEY,

    tm.TIME_KEY,

    pickup.LOCATION_KEY AS PICKUP_LOCATION_KEY,

    dropoff.LOCATION_KEY AS DROPOFF_LOCATION_KEY,

    p.PAYMENT_KEY,

    r.RATE_KEY,

    v.VENDOR_KEY,

    t.PASSENGER_COUNT,
    t.TRIP_DISTANCE,
    t.TRIP_DURATION_MINUTES,

    t.FARE_AMOUNT,
    t.EXTRA,
    t.MTA_TAX,
    t.TIP_AMOUNT,
    t.TOLLS_AMOUNT,
    t.IMPROVEMENT_SURCHARGE,
    t.CONGESTION_SURCHARGE,
    t.AIRPORT_FEE,
    t.CBD_CONGESTION_FEE,
    t.TOTAL_AMOUNT,

    t._SOURCE_FILE,
    t._SOURCE_YEAR,
    t._SOURCE_MONTH,
    t._LOADED_AT

FROM trips t

LEFT JOIN {{ ref('dim_date') }} d
    ON t.PICKUP_DATE = d.FULL_DATE

LEFT JOIN {{ ref('dim_time') }} tm
    ON t.PICKUP_TIME = tm.FULL_TIME

LEFT JOIN {{ ref('dim_location') }} pickup
    ON t.PULOCATIONID = pickup.LOCATIONID

LEFT JOIN {{ ref('dim_location') }} dropoff
    ON t.DOLOCATIONID = dropoff.LOCATIONID

LEFT JOIN {{ ref('dim_payment') }} p
    ON t.PAYMENT_TYPE = p.PAYMENT_TYPE

LEFT JOIN {{ ref('dim_rate') }} r
    ON t.RATECODEID = r.RATECODEID

LEFT JOIN {{ ref('dim_vendor') }} v
    ON t.VENDORID = v.VENDORID
