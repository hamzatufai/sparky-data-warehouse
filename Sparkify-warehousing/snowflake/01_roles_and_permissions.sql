-- =============================================================================
-- 01_roles_and_permissions.sql
-- Creates the foundational Snowflake objects for the Sparkify warehouse:
-- a virtual warehouse, a database, RAW/STAGING/MARTS schemas, a custom role,
-- and the grants that tie them together (RBAC).
-- Run as a user with SECURITYADMIN / SYSADMIN privileges (e.g. ACCOUNTADMIN).
-- =============================================================================

-- Switch to a role capable of creating roles and granting privileges.
USE ROLE SECURITYADMIN;

-- Create a dedicated functional role for the Sparkify project instead of
-- using broad built-in roles - this is the core of least-privilege RBAC.
CREATE ROLE IF NOT EXISTS SPARKIFY_ROLE
  COMMENT = 'Role for Sparkify ETL/ELT pipeline and dbt transformations';

-- Grant the new role to the current user so we can immediately use it
-- to create and own the objects below. In production, grant to a
-- dedicated service user instead of a human user.
SELECT CURRENT_USER();
GRANT ROLE SPARKIFY_ROLE TO USER TOMMASSHELBY;

-- Switch to SYSADMIN, the conventional role for creating warehouses/databases.
USE ROLE SYSADMIN;

-- Create a right-sized virtual warehouse dedicated to Sparkify workloads so
-- compute cost is isolated and easy to monitor/suspend independently.
CREATE WAREHOUSE IF NOT EXISTS SPARKIFY_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60          -- suspend after 60s idle to save credits
  AUTO_RESUME = TRUE         -- resume automatically on next query
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Warehouse for Sparkify ingestion and dbt transformation workloads';

-- Create the database that will hold both raw landing tables and
-- the transformed analytics star schema.
CREATE DATABASE IF NOT EXISTS SPARKIFY_DB
  COMMENT = 'Sparkify cloud data warehouse database';

-- Create the RAW schema: landing zone for untransformed VARIANT JSON data.
CREATE SCHEMA IF NOT EXISTS SPARKIFY_DB.RAW
  COMMENT = 'Raw landing schema holding VARIANT JSON copied in from S3';

-- Create the STAGING schema: dbt writes the typed VARIANT-parsing views here.
CREATE SCHEMA IF NOT EXISTS SPARKIFY_DB.STAGING
  COMMENT = 'Staging schema holding typed views over RAW VARIANT JSON';

-- Create the MARTS schema: dbt writes the final star schema here.
CREATE SCHEMA IF NOT EXISTS SPARKIFY_DB.MARTS
  COMMENT = 'Curated star schema (songplays fact + dimensions) built by dbt';

-- ---------------------------------------------------------------------------
-- Grants: give SPARKIFY_ROLE exactly the privileges it needs, nothing more.
-- ---------------------------------------------------------------------------

-- Allow the role to use the warehouse (required to run any query/COPY/dbt run).
GRANT USAGE, OPERATE ON WAREHOUSE SPARKIFY_WH TO ROLE SPARKIFY_ROLE;

-- Allow the role to see and use the database and all three schemas.
GRANT USAGE ON DATABASE SPARKIFY_DB TO ROLE SPARKIFY_ROLE;
GRANT USAGE ON SCHEMA SPARKIFY_DB.RAW TO ROLE SPARKIFY_ROLE;
GRANT USAGE ON SCHEMA SPARKIFY_DB.STAGING TO ROLE SPARKIFY_ROLE;
GRANT USAGE ON SCHEMA SPARKIFY_DB.MARTS TO ROLE SPARKIFY_ROLE;

-- Allow the role to create the landing tables/stages/file formats in RAW.
GRANT CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA SPARKIFY_DB.RAW TO ROLE SPARKIFY_ROLE;

-- Allow the role (via dbt) to create the staging views.
GRANT CREATE TABLE, CREATE VIEW
  ON SCHEMA SPARKIFY_DB.STAGING TO ROLE SPARKIFY_ROLE;

-- Allow the role (via dbt) to create tables/views for the star schema.
GRANT CREATE TABLE, CREATE VIEW
  ON SCHEMA SPARKIFY_DB.MARTS TO ROLE SPARKIFY_ROLE;

-- Grant SELECT on all current and FUTURE tables/views in every schema so dbt
-- models and BI tools can read data without per-table grant maintenance.
GRANT SELECT ON ALL TABLES IN SCHEMA SPARKIFY_DB.RAW TO ROLE SPARKIFY_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SPARKIFY_DB.RAW TO ROLE SPARKIFY_ROLE;

GRANT SELECT ON ALL TABLES IN SCHEMA SPARKIFY_DB.STAGING TO ROLE SPARKIFY_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SPARKIFY_DB.STAGING TO ROLE SPARKIFY_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA SPARKIFY_DB.STAGING TO ROLE SPARKIFY_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SPARKIFY_DB.STAGING TO ROLE SPARKIFY_ROLE;

GRANT SELECT ON ALL TABLES IN SCHEMA SPARKIFY_DB.MARTS TO ROLE SPARKIFY_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SPARKIFY_DB.MARTS TO ROLE SPARKIFY_ROLE;

-- Finally, hand the role to the executing user (repeat for any service
-- accounts / dbt Cloud connections that need to run the pipeline).
SELECT CURRENT_USER();
GRANT ROLE SPARKIFY_ROLE TO USER <Login name>;

-- Set SPARKIFY_ROLE as the working role and target DB/warehouse for the
-- remaining setup scripts (02 and 03) in this folder.
USE ROLE SPARKIFY_ROLE;
USE WAREHOUSE SPARKIFY_WH;
USE DATABASE SPARKIFY_DB;
