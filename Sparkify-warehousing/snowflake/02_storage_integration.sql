-- =============================================================================
-- 02_storage_integration.sql
-- Creates a Storage Integration (Snowflake's recommended, credential-free way
-- to connect to S3) plus a JSON file format and an External Stage that
-- points at the Sparkify S3 bucket.
-- Run Steps 1 and 2 as ACCOUNTADMIN, then Steps 3+ as SPARKIFY_ROLE.
-- =============================================================================

-- Storage Integrations are account-level objects and require ACCOUNTADMIN
-- (or a role explicitly granted CREATE INTEGRATION) to create.
USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------------
-- Step 1: Create the Storage Integration.
-- STORAGE_AWS_ROLE_ARN is the ARN printed by aws/setup_aws_resources.sh.
-- ---------------------------------------------------------------------------
CREATE STORAGE INTEGRATION IF NOT EXISTS SPARKIFY_S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  -- Replace with the ARN output by setup_aws_resources.sh Step 5.
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::260898618942:role/sparkify_snowflake_s3_role'
  -- Restrict this integration to only the Sparkify bucket/prefixes.
  STORAGE_ALLOWED_LOCATIONS = (
    's3://sparkify-dw-bucket-hamza/data/log_data/',
    's3://sparkify-dw-bucket-hamza/data/song_data/'
)
  COMMENT = 'Storage integration granting Snowflake read access to Sparkify raw data in S3';

-- ---------------------------------------------------------------------------
-- Step 2: Retrieve the auto-generated Snowflake IAM user ARN + External ID.
-- Copy STORAGE_AWS_IAM_USER_ARN -> aws/trust_policy.json "AWS" field, and
-- STORAGE_AWS_EXTERNAL_ID -> aws/trust_policy.json "sts:ExternalId" field.
-- Then re-run: aws iam update-assume-role-policy --role-name
--   sparkify_snowflake_s3_role --policy-document file://aws/trust_policy.json
-- ---------------------------------------------------------------------------
DESC STORAGE INTEGRATION SPARKIFY_S3_INTEGRATION;

-- Allow SPARKIFY_ROLE to use this integration when creating stages.
GRANT USAGE ON INTEGRATION SPARKIFY_S3_INTEGRATION TO ROLE SPARKIFY_ROLE;

-- ---------------------------------------------------------------------------
-- Step 3: Switch to the project role/warehouse/schema for the remaining DDL.
-- ---------------------------------------------------------------------------
USE ROLE SPARKIFY_ROLE;
USE WAREHOUSE SPARKIFY_WH;
USE SCHEMA SPARKIFY_DB.RAW;

-- ---------------------------------------------------------------------------
-- Step 4: Define a reusable JSON file format.
-- STRIP_OUTER_ARRAY = TRUE unwraps a top-level JSON array so each element
-- lands as its own row - useful if any source files are batched as arrays.
-- Sparkify's log/song files are one-JSON-object-per-line, which this format
-- also parses correctly since STRIP_OUTER_ARRAY is a no-op on non-array JSON.
-- ---------------------------------------------------------------------------
CREATE FILE FORMAT IF NOT EXISTS SPARKIFY_DB.RAW.JSON_FORMAT
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE
  COMMENT = 'Standard JSON file format for Sparkify log/song ingestion';

-- ---------------------------------------------------------------------------
-- Step 5: Create the External Stage pointing at the log_data prefix.
-- ---------------------------------------------------------------------------


CREATE STAGE IF NOT EXISTS SPARKIFY_DB.RAW.SONG_DATA_STAGE
  URL = 's3://sparkify-dw-bucket-hamza/data/song_data/'
  STORAGE_INTEGRATION = SPARKIFY_S3_INTEGRATION
  FILE_FORMAT = SPARKIFY_DB.RAW.JSON_FORMAT
  COMMENT = 'External stage for Sparkify song metadata JSON files';

-- ---------------------------------------------------------------------------
-- Step 6: Create the External Stage pointing at the song_data prefix.
-- ---------------------------------------------------------------------------
CREATE STAGE IF NOT EXISTS SPARKIFY_DB.RAW.LOG_DATA_STAGE
  URL = 's3://sparkify-dw-bucket-hamza/data/log_data/'
  STORAGE_INTEGRATION = SPARKIFY_S3_INTEGRATION
  FILE_FORMAT = SPARKIFY_DB.RAW.JSON_FORMAT
  COMMENT = 'External stage for Sparkify user activity log JSON files';

-- Quick sanity check: list files currently visible through each stage.
LIST @SPARKIFY_DB.RAW.LOG_DATA_STAGE;
LIST @SPARKIFY_DB.RAW.SONG_DATA_STAGE;
