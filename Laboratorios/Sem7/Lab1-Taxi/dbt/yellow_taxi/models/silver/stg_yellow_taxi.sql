{{ config(
    materialized='table'
) }}

WITH source_data AS (

    SELECT
        VENDORID,
        TPEP_PICKUP_DATETIME,
        TPEP_DROPOFF_DATETIME,
        PASSENGER_COUNT,
        TRIP_DISTANCE,
        RATECODEID,
        STORE_AND_FWD_FLAG,
        PULOCATIONID,
        DOLOCATIONID,
        PAYMENT_TYPE,
        FARE_AMOUNT,
        EXTRA,
        MTA_TAX,
        TIP_AMOUNT,
        TOLLS_AMOUNT,
        IMPROVEMENT_SURCHARGE,
        TOTAL_AMOUNT,
        CONGESTION_SURCHARGE,
        AIRPORT_FEE,
        CBD_CONGESTION_FEE,

        _SOURCE_FILE,
        _SOURCE_YEAR,
        _SOURCE_MONTH,
        _LOADED_AT

    FROM {{ source('bronze', 'raw_yellow_taxi') }}

),

cleaned AS (

    SELECT

        VENDORID,
        TPEP_PICKUP_DATETIME,
        TPEP_DROPOFF_DATETIME,

        PASSENGER_COUNT,
        TRIP_DISTANCE,
        RATECODEID,
        STORE_AND_FWD_FLAG,

        PULOCATIONID,
        DOLOCATIONID,
        PAYMENT_TYPE,

        FARE_AMOUNT,
        EXTRA,
        MTA_TAX,
        TIP_AMOUNT,
        TOLLS_AMOUNT,
        IMPROVEMENT_SURCHARGE,
        TOTAL_AMOUNT,
        CONGESTION_SURCHARGE,
        AIRPORT_FEE,
        CBD_CONGESTION_FEE,

        DATEDIFF(
            'minute',
            TPEP_PICKUP_DATETIME,
            TPEP_DROPOFF_DATETIME
        ) AS TRIP_DURATION_MINUTES,

        MD5(
            CONCAT_WS(
                '|',
                COALESCE(VENDORID::VARCHAR, ''),
                COALESCE(TPEP_PICKUP_DATETIME::VARCHAR, ''),
                COALESCE(TPEP_DROPOFF_DATETIME::VARCHAR, ''),
                COALESCE(PULOCATIONID::VARCHAR, ''),
                COALESCE(DOLOCATIONID::VARCHAR, ''),
                COALESCE(TOTAL_AMOUNT::VARCHAR, '')
            )
        ) AS TRIP_ID,

        _SOURCE_FILE,
        _SOURCE_YEAR,
        _SOURCE_MONTH,
        _LOADED_AT

    FROM source_data

    WHERE TPEP_PICKUP_DATETIME IS NOT NULL
      AND TPEP_DROPOFF_DATETIME IS NOT NULL

      AND TPEP_DROPOFF_DATETIME >= TPEP_PICKUP_DATETIME

      AND TRIP_DISTANCE >= 0

      AND FARE_AMOUNT >= 0

      AND TOTAL_AMOUNT >= 0

)

SELECT *
FROM cleaned

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIP_ID
    ORDER BY _LOADED_AT
) = 1
