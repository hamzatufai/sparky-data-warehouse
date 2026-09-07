#!/usr/bin/env bash
# =============================================================================
# upload_and_load_data.sh
# End-to-end ingestion step: syncs local Sparkify JSON data (log_data + 
# song_data) up to S3, then invokes SnowCLI to run the COPY INTO statements
# that load the new files into Snowflake's RAW VARIANT tables.
#
# NOTE ON THE LOCAL PATH: the source data lives on a Windows filesystem at
#   C:\Users\Noman Traders\Documents\Sparkify-data-warehousing\data
# This script is written for Git Bash / WSL, both of which expose that path
# as /c/Users/... or /mnt/c/Users/... respectively - the LOCAL_DATA_DIR
# variable below is written in the portable /c/... form used by Git Bash.
# If running under WSL, change it to the /mnt/c/... form (see docs/docs.md).
# =============================================================================

# Stop on error, treat unset vars as errors, and fail pipelines on the first
# failing command (not just the last one) so partial-sync bugs surface loudly.
set -euo pipefail
set -o pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------
# Local Windows path to the Sparkify data folder, in Git-Bash path form.
# Quoted because the folder name "Noman Traders" contains a space.
LOCAL_DATA_DIR="../../data"
# Target S3 bucket created by aws/setup_aws_resources.sh.
BUCKET_NAME="sparkify-dw-bucket-hamza"
# Snowflake connection name as configured in `snow connection add`
# (see docs/docs.md Step 2 for how this is created).
SNOWCLI_CONNECTION="sparkify_conn"

echo "=== Step 1: Verify the local data directory exists ==="
# Fail fast with a clear message rather than a confusing aws cli error
# if the Windows path was mistyped or the drive isn't mounted.
if [ ! -d "${LOCAL_DATA_DIR}" ]; then
  echo "ERROR: Local data directory not found: ${LOCAL_DATA_DIR}"
  echo "If running under WSL, use /mnt/c/... instead of /c/... for this path."
  exit 1
fi

echo "=== Step 2: Sync local log_data/ JSON files to S3 ==="
# aws s3 sync only uploads new/changed files, so re-running this script is
# cheap and safe once the initial upload has completed.
aws s3 sync "${LOCAL_DATA_DIR}/log_data/" "s3://${BUCKET_NAME}/data/log_data/" \
  --exclude "*" \
  --include "*.json"

echo "=== Step 3: Sync local song_data/ JSON files to S3 ==="
# song_data is nested (e.g. song_data/A/A/B/*.json); --recursive is the
# default for `sync`, so nested folders are picked up automatically.
aws s3 sync "${LOCAL_DATA_DIR}/song_data/" "s3://${BUCKET_NAME}/data/song_data/" \
  --exclude "*" \
  --include "*.json"

echo "=== Step 4: Confirm SnowCLI is authenticated against Snowflake ==="
# `snow connection test` validates the named connection before we run SQL,
# so auth problems are caught here instead of mid-COPY.
snow connection test --connection "${SNOWCLI_CONNECTION}"

echo "=== Step 5: Refresh external stage metadata and COPY new files into RAW ==="
# SnowCLI's `snow sql` runs arbitrary SQL against the named connection.
# Re-running COPY INTO is safe: Snowflake tracks already-loaded files via
# load history and will not reload the same file twice by default.
snow sql --connection "${SNOWCLI_CONNECTION}" -q "
  USE ROLE SPARKIFY_ROLE;
  USE WAREHOUSE SPARKIFY_WH;
  USE SCHEMA SPARKIFY_DB.RAW;

  COPY INTO SPARKIFY_DB.RAW.RAW_EVENTS (RAW_PAYLOAD, SOURCE_FILE_NAME)
    FROM (SELECT \$1, METADATA\$FILENAME FROM @SPARKIFY_DB.RAW.LOG_DATA_STAGE)
    FILE_FORMAT = (FORMAT_NAME = SPARKIFY_DB.RAW.JSON_FORMAT)
    ON_ERROR = 'CONTINUE';

  COPY INTO SPARKIFY_DB.RAW.RAW_SONGS (RAW_PAYLOAD, SOURCE_FILE_NAME)
    FROM (SELECT \$1, METADATA\$FILENAME FROM @SPARKIFY_DB.RAW.SONG_DATA_STAGE)
    FILE_FORMAT = (FORMAT_NAME = SPARKIFY_DB.RAW.JSON_FORMAT)
    ON_ERROR = 'CONTINUE';
"

echo "=== Step 6: Print row counts so the load can be sanity-checked ==="
snow sql --connection "${SNOWCLI_CONNECTION}" -q "
  SELECT 'RAW_EVENTS' AS table_name, COUNT(*) AS row_count FROM SPARKIFY_DB.RAW.RAW_EVENTS
  UNION ALL
  SELECT 'RAW_SONGS' AS table_name, COUNT(*) AS row_count FROM SPARKIFY_DB.RAW.RAW_SONGS;
"

echo "=== Done. Data uploaded to S3 and loaded into Snowflake RAW schema. ==="
