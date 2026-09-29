{{ config(
    materialized='table'
) }}

WITH times AS (

    SELECT DISTINCT

        DATE_TRUNC(
            'SECOND',
            TPEP_PICKUP_DATETIME::TIMESTAMP_NTZ
        )::TIME AS FULL_TIME

    FROM {{ ref('stg_yellow_taxi') }}

)

SELECT

    TO_NUMBER(TO_CHAR(FULL_TIME, 'HH24MISS')) AS TIME_KEY,

    FULL_TIME,

    HOUR(FULL_TIME) AS HOUR,

    MINUTE(FULL_TIME) AS MINUTE,

    SECOND(FULL_TIME) AS SECOND,

    CASE
        WHEN HOUR(FULL_TIME) BETWEEN 0 AND 5
            THEN 'Madrugada'

        WHEN HOUR(FULL_TIME) BETWEEN 6 AND 11
            THEN 'Mañana'

        WHEN HOUR(FULL_TIME) BETWEEN 12 AND 17
            THEN 'Tarde'

        ELSE 'Noche'
    END AS PERIOD_OF_DAY

FROM times