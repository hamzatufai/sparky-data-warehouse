-- =============================================================================
-- 03_raw_variant_tables.sql
-- Creates RAW landing tables and loads JSON data from S3 stages.
-- =============================================================================

USE ROLE SPARKIFY_ROLE;
USE WAREHOUSE SPARKIFY_WH;
USE SCHEMA SPARKIFY_DB.RAW;

-- -----------------------------------------------------------------------------
-- RAW_EVENTS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS SPARKIFY_DB.RAW.RAW_EVENTS (
    RAW_PAYLOAD VARIANT,
    SOURCE_FILE_NAME STRING DEFAULT NULL,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Raw landing table for Sparkify log_data JSON event payloads';

-- -----------------------------------------------------------------------------
-- RAW_SONGS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS SPARKIFY_DB.RAW.RAW_SONGS (
    RAW_PAYLOAD VARIANT,
    SOURCE_FILE_NAME STRING DEFAULT NULL,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Raw landing table for Sparkify song_data JSON metadata payloads';

-- -----------------------------------------------------------------------------
-- Load log_data
-- -----------------------------------------------------------------------------

COPY INTO SPARKIFY_DB.RAW.RAW_EVENTS
    (RAW_PAYLOAD, SOURCE_FILE_NAME)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @SPARKIFY_DB.RAW.LOG_DATA_STAGE
)
FILE_FORMAT = (
    FORMAT_NAME = SPARKIFY_DB.RAW.JSON_FORMAT
)
ON_ERROR = 'CONTINUE';

-- -----------------------------------------------------------------------------
-- Load song_data
-- -----------------------------------------------------------------------------

COPY INTO SPARKIFY_DB.RAW.RAW_SONGS
    (RAW_PAYLOAD, SOURCE_FILE_NAME)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @SPARKIFY_DB.RAW.SONG_DATA_STAGE
)
FILE_FORMAT = (
    FORMAT_NAME = SPARKIFY_DB.RAW.JSON_FORMAT
)
ON_ERROR = 'CONTINUE';

-- -----------------------------------------------------------------------------
-- Verification
-- -----------------------------------------------------------------------------

SELECT COUNT(*) AS raw_events_row_count
FROM SPARKIFY_DB.RAW.RAW_EVENTS;

SELECT COUNT(*) AS raw_songs_row_count
FROM SPARKIFY_DB.RAW.RAW_SONGS;

-- -----------------------------------------------------------------------------
-- Inspect JSON
-- -----------------------------------------------------------------------------

SELECT
    RAW_PAYLOAD:userId::INT AS user_id,
    RAW_PAYLOAD:page::STRING AS page,
    RAW_PAYLOAD:ts::BIGINT AS ts_epoch_ms
FROM SPARKIFY_DB.RAW.RAW_EVENTS
LIMIT 10;