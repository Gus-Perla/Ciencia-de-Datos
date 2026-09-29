-- ============================================================
-- 01. BASE DE DATOS, SCHEMAS Y WAREHOUSE
-- ============================================================

CREATE DATABASE IF NOT EXISTS NYC_TAXI;

USE DATABASE NYC_TAXI;

CREATE SCHEMA IF NOT EXISTS BRONZE;
CREATE SCHEMA IF NOT EXISTS SILVER;
CREATE SCHEMA IF NOT EXISTS GOLD;

CREATE WAREHOUSE IF NOT EXISTS TAXI_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TAXI_WH;


-- ============================================================
-- 02. FILE FORMAT PARA LOS PARQUET DE NYC TLC
-- ============================================================

CREATE FILE FORMAT IF NOT EXISTS BRONZE.YELLOW_PARQUET_FORMAT
    TYPE = PARQUET
    USE_LOGICAL_TYPE = TRUE;


-- ============================================================
-- 03. STAGE PARA LOS ARCHIVOS ORIGINALES
-- ============================================================

CREATE STAGE IF NOT EXISTS BRONZE.YELLOW_TAXI_STAGE
    FILE_FORMAT = BRONZE.YELLOW_PARQUET_FORMAT;


-- ============================================================
-- 04. TABLA BRONZE
--     Mantiene los datos cercanos a la fuente original
--     y agrega metadatos de ingestión.
-- ============================================================

CREATE TABLE IF NOT EXISTS BRONZE.RAW_YELLOW_TAXI (
    VENDORID NUMBER,
    TPEP_PICKUP_DATETIME TIMESTAMP_NTZ,
    TPEP_DROPOFF_DATETIME TIMESTAMP_NTZ,
    PASSENGER_COUNT NUMBER,
    TRIP_DISTANCE FLOAT,
    RATECODEID NUMBER,
    STORE_AND_FWD_FLAG VARCHAR,
    PULOCATIONID NUMBER,
    DOLOCATIONID NUMBER,
    PAYMENT_TYPE NUMBER,
    FARE_AMOUNT FLOAT,
    EXTRA FLOAT,
    MTA_TAX FLOAT,
    TIP_AMOUNT FLOAT,
    TOLLS_AMOUNT FLOAT,
    IMPROVEMENT_SURCHARGE FLOAT,
    TOTAL_AMOUNT FLOAT,
    CONGESTION_SURCHARGE FLOAT,
    AIRPORT_FEE FLOAT,
    CBD_CONGESTION_FEE FLOAT,

    _SOURCE_FILE VARCHAR,
    _SOURCE_YEAR NUMBER,
    _SOURCE_MONTH NUMBER,
    _LOADED_AT TIMESTAMP_NTZ
);


-- ============================================================
-- 05. TABLA DE AUDITORÍA DE INGESTIÓN
--     Sirve para demostrar idempotencia.
-- ============================================================

CREATE TABLE IF NOT EXISTS BRONZE.INGESTION_LOG (
    SOURCE_FILE VARCHAR PRIMARY KEY,
    SOURCE_YEAR NUMBER,
    SOURCE_MONTH NUMBER,
    LOADED_AT TIMESTAMP_NTZ,
    ROW_COUNT NUMBER,
    STATUS VARCHAR
);


-- ============================================================
-- 06. VERIFICAR ESTRUCTURA BRONZE
-- ============================================================

SHOW TABLES IN SCHEMA NYC_TAXI.BRONZE;

DESC TABLE NYC_TAXI.BRONZE.RAW_YELLOW_TAXI;

DESC TABLE NYC_TAXI.BRONZE.INGESTION_LOG;


-- ============================================================
-- 07. VERIFICAR LOS MESES INGRESADOS
-- ============================================================

SELECT
    SOURCE_YEAR,
    COUNT(*) AS MESES,
    SUM(ROW_COUNT) AS FILAS
FROM NYC_TAXI.BRONZE.INGESTION_LOG
WHERE STATUS = 'SUCCESS'
GROUP BY SOURCE_YEAR
ORDER BY SOURCE_YEAR;


-- ============================================================
-- 08. VERIFICAR LOS 20 PERIODOS
-- ============================================================

SELECT
    SOURCE_YEAR,
    SOURCE_MONTH,
    SOURCE_FILE,
    ROW_COUNT,
    STATUS,
    LOADED_AT
FROM NYC_TAXI.BRONZE.INGESTION_LOG
ORDER BY SOURCE_YEAR, SOURCE_MONTH;


-- ============================================================
-- 09. VERIFICAR CANTIDAD TOTAL DE PERIODOS
-- ============================================================

SELECT
    COUNT(*) AS MESES_CARGADOS
FROM NYC_TAXI.BRONZE.INGESTION_LOG
WHERE STATUS = 'SUCCESS';


-- ============================================================
-- 10. VERIFICAR CANTIDAD DE REGISTROS EN BRONZE
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_REGISTROS
FROM NYC_TAXI.BRONZE.RAW_YELLOW_TAXI;


-- ============================================================
-- 11. VERIFICAR QUE LOS DATOS ESTÉN DISTRIBUIDOS
--     POR AÑO Y MES
-- ============================================================

SELECT
    _SOURCE_YEAR AS YEAR,
    _SOURCE_MONTH AS MONTH,
    COUNT(*) AS ROWS
FROM NYC_TAXI.BRONZE.RAW_YELLOW_TAXI
GROUP BY
    _SOURCE_YEAR,
    _SOURCE_MONTH
ORDER BY
    YEAR,
    MONTH;


-- ============================================================
-- 12. VERIFICAR FECHAS DE LOS DATOS
-- ============================================================

SELECT
    MIN(TPEP_PICKUP_DATETIME) AS MIN_PICKUP,
    MAX(TPEP_PICKUP_DATETIME) AS MAX_PICKUP
FROM NYC_TAXI.BRONZE.RAW_YELLOW_TAXI;


-- ============================================================
-- 13. VERIFICAR ALGUNAS FILAS
-- ============================================================

SELECT *
FROM NYC_TAXI.BRONZE.RAW_YELLOW_TAXI
LIMIT 20;


-- ============================================================
-- 14. CREAR SILVER
-- ============================================================

CREATE SCHEMA IF NOT EXISTS NYC_TAXI.SILVER;


-- ============================================================
-- 15. CREAR GOLD
-- ============================================================

CREATE SCHEMA IF NOT EXISTS NYC_TAXI.GOLD;


-- ============================================================
-- 16. VERIFICAR LOS SCHEMAS
-- ============================================================

SHOW SCHEMAS IN DATABASE NYC_TAXI;