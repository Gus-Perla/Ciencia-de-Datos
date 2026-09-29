import os
import requests
import snowflake.connector
from pathlib import Path


# ============================================================
# CONFIGURACIÓN
# ============================================================

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data/"

DATA_DIR = Path("/data")
DATA_DIR.mkdir(parents=True, exist_ok=True)


# Todos los períodos que necesita el laboratorio
PERIODS = (
    [(2025, month) for month in range(1, 13)]
    + [(2026, month) for month in range(1, 7)]
)


# ============================================================
# CONEXIÓN A SNOWFLAKE
# ============================================================

def create_connection():

    print("Conectando a Snowflake...")

    conn = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=os.environ["SNOWFLAKE_SCHEMA"],
    )

    print("Conexión exitosa.")

    return conn


# ============================================================
# DESCARGAR ARCHIVO
# ============================================================

def download_file(year, month):

    filename = f"yellow_tripdata_{year}-{month:02d}.parquet"

    url = BASE_URL + filename

    local_file = DATA_DIR / filename

    print("\n" + "=" * 60)
    print(f"PERÍODO: {year}-{month:02d}")
    print(f"Archivo: {filename}")
    print(f"URL:     {url}")
    print("=" * 60)

    # Si ya existe localmente, no volver a descargar
    if local_file.exists():

        print("El archivo ya existe localmente.")
        print(f"Tamaño: {local_file.stat().st_size / (1024**2):.2f} MB")

        return local_file

    print("Descargando...")

    response = requests.get(
        url,
        stream=True,
        timeout=120
    )

    response.raise_for_status()

    with open(local_file, "wb") as f:

        for chunk in response.iter_content(
            chunk_size=1024 * 1024
        ):

            if chunk:
                f.write(chunk)

    print("Descarga completada.")

    print(
        f"Tamaño: "
        f"{local_file.stat().st_size / (1024**2):.2f} MB"
    )

    return local_file


# ============================================================
# COMPROBAR SI YA FUE CARGADO
# ============================================================

def already_loaded(cursor, filename):

    cursor.execute(
        """
        SELECT SOURCE_FILE
        FROM BRONZE.INGESTION_LOG
        WHERE SOURCE_FILE = %s
          AND STATUS = 'SUCCESS'
        """,
        (filename,)
    )

    result = cursor.fetchone()

    return result is not None


# ============================================================
# SUBIR AL STAGE
# ============================================================

def upload_to_stage(cursor, local_file, year, month):

    filename = local_file.name

    stage_path = (
        f"@BRONZE.YELLOW_TAXI_STAGE/"
        f"{year}/{month:02d}/"
    )

    print("\nSubiendo al Stage...")

    put_sql = f"""
        PUT 'file://{local_file}'
        {stage_path}
        AUTO_COMPRESS=FALSE
        OVERWRITE=TRUE
    """

    cursor.execute(put_sql)

    result = cursor.fetchall()

    print("Archivo subido al Stage.")

    for row in result:
        print(row)

    return stage_path


# ============================================================
# CARGAR BRONZE
# ============================================================

def load_to_bronze(
    cursor,
    stage_path,
    filename,
    year,
    month
):

    print("\nCargando datos en BRONZE...")

    copy_sql = f"""
        COPY INTO BRONZE.RAW_YELLOW_TAXI
        FROM (
            SELECT
                $1:vendorid::NUMBER,
                $1:tpep_pickup_datetime::TIMESTAMP_NTZ,
                $1:tpep_dropoff_datetime::TIMESTAMP_NTZ,
                $1:passenger_count::NUMBER,
                $1:trip_distance::FLOAT,
                $1:ratecodeid::NUMBER,
                $1:store_and_fwd_flag::VARCHAR,
                $1:pulocationid::NUMBER,
                $1:dolocationid::NUMBER,
                $1:payment_type::NUMBER,
                $1:fare_amount::FLOAT,
                $1:extra::FLOAT,
                $1:mta_tax::FLOAT,
                $1:tip_amount::FLOAT,
                $1:tolls_amount::FLOAT,
                $1:improvement_surcharge::FLOAT,
                $1:total_amount::FLOAT,
                $1:congestion_surcharge::FLOAT,
                $1:airport_fee::FLOAT,
                $1:cbd_congestion_fee::FLOAT,

                '{filename}',
                {year},
                {month},
                CURRENT_TIMESTAMP()

            FROM {stage_path}
        )

        FILE_FORMAT = (
            TYPE = PARQUET
            USE_LOGICAL_TYPE = TRUE
        )

        ON_ERROR = 'ABORT_STATEMENT'
    """

    cursor.execute(copy_sql)

    result = cursor.fetchall()

    print("COPY INTO completado.")

    for row in result:
        print(row)


# ============================================================
# CONTAR FILAS
# ============================================================

def count_loaded_rows(cursor, filename):

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM BRONZE.RAW_YELLOW_TAXI
        WHERE _SOURCE_FILE = %s
        """,
        (filename,)
    )

    result = cursor.fetchone()

    return result[0]


# ============================================================
# REGISTRAR INGESTIÓN
# ============================================================

def register_ingestion(
    cursor,
    filename,
    year,
    month,
    row_count
):

    cursor.execute(
        """
        INSERT INTO BRONZE.INGESTION_LOG
        (
            SOURCE_FILE,
            SOURCE_YEAR,
            SOURCE_MONTH,
            LOADED_AT,
            ROW_COUNT,
            STATUS
        )
        VALUES (
            %s,
            %s,
            %s,
            CURRENT_TIMESTAMP(),
            %s,
            'SUCCESS'
        )
        """,
        (
            filename,
            year,
            month,
            row_count
        )
    )


# ============================================================
# PROCESAR UN PERÍODO
# ============================================================

def process_period(cursor, year, month):

    filename = (
        f"yellow_tripdata_{year}-{month:02d}.parquet"
    )

    print("\n")
    print("#" * 70)
    print(f"# PROCESANDO {year}-{month:02d}")
    print("#" * 70)

    # --------------------------------------------------------
    # 1. Comprobar si ya está cargado
    # --------------------------------------------------------

    if already_loaded(cursor, filename):

        print(
            f"\n{filename} ya fue cargado anteriormente."
        )

        print("Se omite este período.")

        return

    # --------------------------------------------------------
    # 2. Descargar
    # --------------------------------------------------------

    local_file = download_file(
        year,
        month
    )

    # --------------------------------------------------------
    # 3. Subir al Stage
    # --------------------------------------------------------

    stage_path = upload_to_stage(
        cursor,
        local_file,
        year,
        month
    )

    # --------------------------------------------------------
    # 4. Cargar Bronze
    # --------------------------------------------------------

    load_to_bronze(
        cursor,
        stage_path,
        filename,
        year,
        month
    )

    # --------------------------------------------------------
    # 5. Contar filas
    # --------------------------------------------------------

    row_count = count_loaded_rows(
        cursor,
        filename
    )

    print(
        f"\nFilas cargadas para {filename}: "
        f"{row_count:,}"
    )

    # --------------------------------------------------------
    # 6. Registrar ingestión
    # --------------------------------------------------------

    register_ingestion(
        cursor,
        filename,
        year,
        month,
        row_count
    )

    # Guardar inmediatamente
    cursor.connection.commit()

    print(
        f"Ingestión registrada: {filename}"
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("\n")
    print("=" * 70)
    print("      NYC YELLOW TAXI - INGESTIÓN COMPLETA")
    print("=" * 70)

    print("\nPeríodos configurados:")

    for year, month in PERIODS:

        print(
            f"  - {year}-{month:02d}"
        )

    print(
        f"\nTotal de períodos: {len(PERIODS)}"
    )

    # --------------------------------------------------------
    # Conexión
    # --------------------------------------------------------

    conn = create_connection()

    cursor = conn.cursor()

    try:

        # ----------------------------------------------------
        # Procesar todos los períodos
        # ----------------------------------------------------

        for year, month in PERIODS:

            try:

                process_period(
                    cursor,
                    year,
                    month
                )

            except Exception as error:

                print("\n" + "!" * 70)
                print(
                    f"ERROR PROCESANDO "
                    f"{year}-{month:02d}"
                )
                print("!" * 70)

                print(error)

                # Revertir cualquier transacción
                # pendiente
                conn.rollback()

                # Continuar con el siguiente período
                print(
                    "\nSe continúa con el "
                    "siguiente período."
                )

    finally:

        cursor.close()
        conn.close()

        print("\nConexión cerrada.")

    print("\n")
    print("=" * 70)
    print("      INGESTIÓN FINALIZADA")
    print("=" * 70)


# ============================================================
# EJECUTAR
# ============================================================

if __name__ == "__main__":
    main()