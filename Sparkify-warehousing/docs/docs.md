# Sparkify Cloud Data Warehouse — Execution Guide

This guide walks through running the entire pipeline end-to-end: local JSON

data → S3 → Snowflake RAW (VARIANT) → dbt star schema in STAGING → MARTS.

Existing project files (**`README.md`**, **`images/`**, **`data/`**) are untouched — this

guide only adds the new **`aws/`**, **`scripts/`**, **`snowflake/`**, **`dbt_sparkify/`**,

and **`docs/`** folders alongside them.

---

## 0. Prerequisites

Install and configure these tools before starting:

| Tool                         | Install                                           | Verify               |
| ---------------------------- | ------------------------------------------------- | -------------------- |
| AWS CLI v2                   | https://aws.amazon.com/cli/                       | **`aws --version`**  |
| SnowCLI                      | **`pip install snowflake-cli-labs`**              | **`snow --version`** |
| dbt Core + Snowflake adapter | **`pip install dbt-snowflake`**                   | **`dbt --version`**  |
| Snowflake account            | with **`ACCOUNTADMIN`** access for one-time setup | —                    |
| AWS account                  | with permissions to create S3 buckets / IAM roles | —                    |

Configure AWS CLI credentials once:

```bash
aws configure

# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region name: us-east-1
# Default output format: json
```

Confirm your local data folder exists at:

```text
C:\Users\Noman Traders\Documents\Sparkify-data-warehousing\data

├── log_data\...
└── song_data\...
```

---

## 1. Provision AWS resources (S3 bucket + IAM role)

```bash
cd Sparkify-warehousing/aws

chmod +x setup_aws_resources.sh

./setup_aws_resources.sh
```

This creates:

* S3 bucket **`sparkify-dw-bucket-hamza`** with **`log_data/`** and **`song_data/`** prefixes.
* IAM role **`sparkify_snowflake_s3_role`** with the **`iam_policy.json`** permissions attached.

**Copy the Role ARN printed at the end of the script** — you'll paste it into

**`snowflake/02_storage_integration.sql`** in the next section.

> *Note:* **`trust_policy.json`** *currently has placeholder values. You'll update*
>
> *and re-apply it in Step 3 below, after Snowflake generates its IAM user ARN*
>
> *and external ID.*

---

## 2. Set up Snowflake roles, warehouse, and schemas

Open a Snowflake worksheet (or use **`snow sql`**) as a user with **`SECURITYADMIN`**/

**`SYSADMIN`** privileges, and run:

```bash
snow sql -f ../snowflake/02_storage_integration.sql --connection <your_admin_connection>
```

This creates:

* Warehouse **`SPARKIFY_WH`**
* Database **`SPARKIFY_DB`** with schemas **`RAW`**, **`STAGING`**, and **`MARTS`**
* Role **`SPARKIFY_ROLE`** with least-privilege grants

---

## 3. Create the Storage Integration and connect it to S3

**1.** In **`snowflake/02_storage_integration.sql`**, replace the placeholder in

**`STORAGE_AWS_ROLE_ARN`** with the Role ARN from Step 1.

**2.** Run the script as **`ACCOUNTADMIN`**:

```bash
snow sql -f ../snowflake/02_storage_integration.sql --connection <your_admin_connection>
```

**3.** The script runs **`DESC STORAGE INTEGRATION SPARKIFY_S3_INTEGRATION;`** —

copy two values from the output:

* **`STORAGE_AWS_IAM_USER_ARN`** → paste into **`aws/trust_policy.json`** **`"AWS"`** field
* **`STORAGE_AWS_EXTERNAL_ID`** → paste into **`aws/trust_policy.json`** **`"sts:ExternalId"`** field

**4.** Re-apply the completed trust policy so AWS actually trusts Snowflake:

```bash
cd ../aws

aws iam update-assume-role-policy \
  --role-name sparkify_snowflake_s3_role \
  --policy-document file://trust_policy.json
```

**5.** Confirm the stages can see files (run again after Step 4 uploads data):

```sql
LIST @SPARKIFY_DB.RAW.LOG_DATA_STAGE;

LIST @SPARKIFY_DB.RAW.SONG_DATA_STAGE;
```

---

## 4. Create RAW landing tables

```bash
snow sql -f ../snowflake/03_raw_variant_tables.sql --connection <your_sparkify_connection>
```

This creates **`RAW.RAW_EVENTS`** and **`RAW.RAW_SONGS`** (VARIANT columns) and runs

an initial **`COPY INTO`** (which will load 0 rows until Step 5 uploads data —

that's expected on a fresh setup).

---

## 5. Upload local data to S3 and load into Snowflake

First, register a SnowCLI connection (one-time):

```bash
snow connection add --connection-name sparkify_conn \
  --account YOUR_ACCOUNT \
  --user YOUR_USERNAME \
  --role YOUR_ROLE \
  --warehouse YOUR_WAREHOUSE \
  --database YOUR_DATABASE \
  --schema YOUR_SCHEMA
```

Then run the ingestion script:

```bash
cd ../scripts

chmod +x upload_and_load_data.sh

./upload_and_load_data.sh
```

**If running under WSL instead of Git Bash**, edit **`LOCAL_DATA_DIR`** in

**`upload_and_load_data.sh`** from:

```text
/c/Users/Noman Traders/Documents/Sparkify-data-warehousing/data
```

to:

```text
/mnt/c/Users/Noman Traders/Documents/Sparkify-data-warehousing/data
```

This script:

**1.** Syncs **`log_data/`** and **`song_data/`** from your local Windows path to S3.

**2.** Runs **`COPY INTO`** via SnowCLI to load new files into **`RAW_EVENTS`** / **`RAW_SONGS`**.

**3.** Prints row counts so you can confirm the load succeeded.

---

## 6. Configure and run dbt

Copy the profile template to dbt's global config location and fill in real credentials:

```bash
mkdir -p ~/.dbt

cp ../dbt_sparkify/profiles.yml.template ~/.dbt/profiles.yml

# edit ~/.dbt/profiles.yml: account, user, password
```

From inside the dbt project folder, verify the connection, then run the models:

```bash
cd ../dbt_sparkify

dbt debug          # confirms Snowflake connectivity

dbt run            # builds staging views + mart tables

dbt test           # runs the 17 schema tests (unique / not_null / relationships)
```

Expected build order (dbt resolves this automatically via **`ref()`**/**`source()`**):

```text
staging_events, staging_songs

   → users, songs, artists, time

      → songplays
```

Layer → schema mapping is set by **`+schema:`** in **`dbt_project.yml`** and resolved
verbatim by **`macros/generate_schema_name.sql`**:

```text
models/staging/*  → SPARKIFY_DB.STAGING   (views)
models/marts/*    → SPARKIFY_DB.MARTS     (tables)
```

---

## 7. Verification queries

Run these in a Snowflake worksheet (or **`snow sql -q "..."`**) to confirm the

star schema built correctly:

```sql
USE ROLE SPARKIFY_ROLE;

USE WAREHOUSE SPARKIFY_WH;

USE SCHEMA SPARKIFY_DB.MARTS;

-- Row counts across the star schema.

SELECT 'users' AS tbl, COUNT(*) FROM USERS
UNION ALL SELECT 'songs', COUNT(*) FROM SONGS
UNION ALL SELECT 'artists', COUNT(*) FROM ARTISTS
UNION ALL SELECT 'time', COUNT(*) FROM "TIME"
UNION ALL SELECT 'songplays', COUNT(*) FROM SONGPLAYS;

-- Top 10 most-played songs (matched against the song catalog).

SELECT s.title, a.name AS artist_name, COUNT(*) AS play_count
FROM SONGPLAYS f
JOIN SONGS s ON f.song_id = s.song_id
JOIN ARTISTS a ON f.artist_id = a.artist_id
GROUP BY 1, 2
ORDER BY play_count DESC
LIMIT 10;

-- Songplays by hour of day, using the time dimension.

SELECT t.hour, COUNT(*) AS plays
FROM SONGPLAYS f
JOIN "TIME" t ON f.start_time = t.start_time
GROUP BY 1
ORDER BY 1;

-- Paid vs. free plays.

SELECT level, COUNT(*) AS plays
FROM SONGPLAYS
GROUP BY level;
```

---

## 8. Re-running the pipeline

The pipeline is designed to be safely re-run end-to-end:

```bash
cd scripts && ./upload_and_load_data.sh   # sync any new local files + COPY INTO

cd ../dbt_sparkify && dbt run               # rebuild the star schema
```

**`aws s3 sync`** only uploads changed files, Snowflake's load history prevents

duplicate **`COPY INTO`** loads of the same file, and **`songplays`**'s surrogate

key is generated with a deterministic **`ROW_NUMBER()`** ordering, so re-running

**`dbt run`** produces the same fact rows rather than duplicating them.

---

## 9. Troubleshooting

| Symptom                                 | Likely cause                                                                     | Fix                                                                                                      |
| --------------------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **`LIST @stage`** returns nothing       | Storage integration trust policy not updated                                     | Redo Step 3.3–3.4                                                                                        |
| **`COPY INTO`** loads 0 rows            | Files already loaded previously                                                  | Expected — Snowflake dedupes by file; check **`raw_events`**/**`raw_songs`** row counts instead          |
| **`dbt debug`** fails to connect        | Wrong account identifier format                                                  | Use **`<orgname>-<accountname>`** or **`<locator>.<region>`** form from Snowflake's "Account" page       |
| **`songplays.song_id`** mostly NULL     | Log data's song/artist titles don't match the (intentionally small) song catalog | Expected with the sample dataset — only a few songs in **`song_data`** match log events. Keep the **`LEFT JOIN`**; an **`INNER JOIN`** drops the fact table to ~30 rows |
| AWS CLI **`AccessDenied`**              | IAM user running the script lacks S3/IAM admin permissions                       | Attach **`AmazonS3FullAccess`** + **`IAMFullAccess`** (or scoped equivalents) to your CLI user for setup |

---

# Additional Commands Used During the Actual Project Setup

## A. Go to the actual project directory

```bash
cd ~/Documents/Sparkify-data-warehousing/Sparkify-warehousing
```

## B. Verify AWS, SnowCLI, and dbt

```bash
aws --version

snow --version

dbt --version
```

## C. Verify the AWS identity currently being used

```bash
aws sts get-caller-identity
```

## D. Verify the actual S3 bucket

```bash
aws s3 ls s3://sparkify-dw-bucket-hamza/
```

## E. Verify the actual S3 data

```bash
aws s3 ls s3://sparkify-dw-bucket-hamza/data/ --recursive
```

## F. Verify the actual log data location

```bash
aws s3 ls s3://sparkify-dw-bucket-hamza/data/log_data/
```

## G. Verify the actual song data location

```bash
aws s3 ls s3://sparkify-dw-bucket-hamza/data/song_data/
```

## H. Check SnowCLI connections

```bash
snow connection list
```

## I. Check the Snowflake storage integration

```sql
DESC STORAGE INTEGRATION SPARKIFY_S3_INTEGRATION;
```

## J. Verify the Snowflake external stages

```sql
LIST @SPARKIFY_DB.RAW.LOG_DATA_STAGE;

LIST @SPARKIFY_DB.RAW.SONG_DATA_STAGE;
```

## K. Verify RAW table row counts

```sql
SELECT COUNT(*) AS raw_events_row_count
FROM SPARKIFY_DB.RAW.RAW_EVENTS;

SELECT COUNT(*) AS raw_songs_row_count
FROM SPARKIFY_DB.RAW.RAW_SONGS;
```

## L. Inspect raw event JSON

```sql
SELECT
    RAW_PAYLOAD:userId::INT AS user_id,
    RAW_PAYLOAD:page::STRING AS page,
    RAW_PAYLOAD:ts::BIGINT AS ts_epoch_ms
FROM SPARKIFY_DB.RAW.RAW_EVENTS
LIMIT 10;
```

## M. Check dbt profile

```bash
cat ~/.dbt/profiles.yml
```

## N. Verify the dbt project configuration

```bash
grep -n -A15 "^models:" dbt_project.yml
```

## O. Find schema overrides in dbt files

```bash
grep -RIn "+schema:" .
```

## P. Check the staging events model

```bash
cat models/staging/staging_events.sql
```

## Q. Check available dbt models

```bash
dbt ls --resource-type model
```

## R. Check available dbt tests

```bash
dbt ls --resource-type test
```

## S. Clean dbt generated objects

```bash
dbt clean
```

## T. Verify dbt connection

```bash
dbt debug
```

## U. Run only staging models

```bash
dbt run --select staging
```

## V. Run only mart models

```bash
dbt run --select marts
```

## W. Run only staging_events

```bash
dbt run --select staging_events
```

## X. Run only staging_songs

```bash
dbt run --select staging_songs
```

## Y. Run the complete dbt project

```bash
dbt run
```

## Z. Run all dbt tests

```bash
dbt test
```

---

# Final Verification Commands

## Check all STAGING views

```sql
SHOW VIEWS IN SCHEMA SPARKIFY_DB.STAGING;
```

## Check all MARTS tables

```sql
SHOW TABLES IN SCHEMA SPARKIFY_DB.MARTS;
```

## Check staging events

```sql
SELECT *
FROM SPARKIFY_DB.STAGING.STAGING_EVENTS
LIMIT 10;
```

## Check staging songs

```sql
SELECT *
FROM SPARKIFY_DB.STAGING.STAGING_SONGS
LIMIT 10;
```

## Check the final fact table

```sql
SELECT *
FROM SPARKIFY_DB.MARTS.SONGPLAYS
LIMIT 10;
```

## Check all star-schema row counts

```sql
SELECT 'users' AS tbl, COUNT(*) AS row_count
FROM SPARKIFY_DB.MARTS.USERS

UNION ALL

SELECT 'songs', COUNT(*)
FROM SPARKIFY_DB.MARTS.SONGS

UNION ALL

SELECT 'artists', COUNT(*)
FROM SPARKIFY_DB.MARTS.ARTISTS

UNION ALL

SELECT 'time', COUNT(*)
FROM SPARKIFY_DB.MARTS."TIME"

UNION ALL

SELECT 'songplays', COUNT(*)
FROM SPARKIFY_DB.MARTS.SONGPLAYS;
```

---

# Current Project Values

These are the actual values used in the completed project:

```text
AWS Region:
us-east-1

S3 Bucket:
sparkify-dw-bucket-hamza

S3 Log Data:
s3://sparkify-dw-bucket-hamza/data/log_data/

S3 Song Data:
s3://sparkify-dw-bucket-hamza/data/song_data/

AWS IAM Role:
sparky-2026

AWS IAM Role ARN:
arn:aws:iam::260898618942:role/sparky-2026

Snowflake Storage Integration:
SPARKIFY_S3_INTEGRATION

Snowflake Database:
SPARKIFY_DB

RAW Schema:
RAW

Staging Schema:
STAGING

Marts Schema:
MARTS

Snowflake Warehouse:
SPARKIFY_WH

Snowflake Role:
SPARKIFY_ROLE

SnowCLI Connection:
sparkify_admin

dbt Profile:
sparkify_dw
```

---

# Final End-to-End Run

```bash
# Go to the project
cd ~/Documents/Sparkify-data-warehousing/Sparkify-warehousing

# Verify AWS
aws sts get-caller-identity

# Verify S3 data
aws s3 ls s3://sparkify-dw-bucket-hamza/data/ --recursive

# Check SnowCLI connection
snow connection list

# Run Snowflake setup scripts
snow sql -c sparkify_admin -f snowflake/01_roles_and_permissions.sql

snow sql -c sparkify_admin -f snowflake/02_storage_integration.sql

snow sql -c sparkify_admin -f snowflake/03_raw_variant_tables.sql

# Upload local data to S3 and load RAW tables
cd scripts

chmod +x upload_and_load_data.sh

./upload_and_load_data.sh

# Go to dbt
cd ../dbt_sparkify

# Check dbt connection
dbt debug

# Clean previous dbt objects
dbt clean

# Build the complete star schema
dbt run

# Run dbt tests
dbt test

# Show dbt models
dbt ls --resource-type model
```

# Expected Final Structure

```text
SPARKIFY_DB
│
├── RAW
│   ├── RAW_EVENTS       (VARIANT landing table)
│   └── RAW_SONGS        (VARIANT landing table)
│
├── STAGING
│   ├── STAGING_EVENTS   (VIEW)
│   └── STAGING_SONGS    (VIEW)
│
└── MARTS
    ├── USERS            (TABLE)  user_id, first_name, last_name, gender, level
    ├── SONGS            (TABLE)  song_id, title, artist_id, year, duration
    ├── ARTISTS          (TABLE)  artist_id, name, location, latitude, longitude
    ├── TIME             (TABLE)  start_time, hour, day, week, month, year, weekday
    └── SONGPLAYS        (TABLE)  songplay_id, start_time, user_id, level,
                                  song_id, artist_id, session_id, location, user_agent
```
