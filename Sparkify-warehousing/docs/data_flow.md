# Sparkify Cloud Data Warehouse — Data Flow Diagram

This document shows how data moves through the system from raw source files to the final analytical model.

## Overview

    Local JSON Files
           |
           v
      AWS S3 Bucket
           |
           v
   Snowflake RAW Schema  (VARIANT tables)
           |
           v
   Snowflake STAGING Schema  (Typed views)
           |
           v
   Snowflake MARTS Schema  (Star schema tables)

## Detailed Flow

### Layer 1: AWS S3

Local JSON files are synced from the machine to an S3 bucket using the AWS CLI.

Two source prefixes are maintained:
- song_data/ — 71 nested JSON files containing song metadata
- log_data/ — 30 daily JSON files containing user activity events

The IAM user authenticates through a scoped profile with no shared credentials.

### Layer 2: Snowflake RAW

Data lands in two VARIANT tables inside the RAW schema:
- RAW_EVENTS — 8,056 event records from log_data
- RAW_SONGS — 71 song records from song_data

Each row preserves the original JSON payload plus two lineage columns:
- SOURCE_FILE_NAME — the file the record came from
- LOADED_AT — the timestamp of ingestion

Loading is performed with the COPY INTO command referencing external stages that point at the S3 prefixes. The file format is JSON with strip outer array enabled.

### Layer 3: Snowflake STAGING

Two dbt views sit in the STAGING schema and parse the VARIANT payloads into typed columns.

staging_events
- Filters to page = NextSong only
- Extracts userId, firstName, lastName, gender, level, sessionId, itemInSession, page, location, userAgent, song, artist, length, ts, registration
- Produces start_time as a bigint epoch value and event_timestamp as a proper TIMESTAMP

staging_songs
- Extracts song_id, title, year, duration, artist_id, artist_name, artist_location, artist_latitude, artist_longitude

Both views reference the RAW tables through dbt source() declarations. No data is duplicated or stored here.

### Layer 4: Snowflake MARTS

Five dbt materialized tables form the star schema in the MARTS schema.

Fact Table
- songplays — one row per song play. Contains songplay_id, start_time, user_id, level, song_id, artist_id, session_id, location, user_agent. Built with a LEFT JOIN from staging_events to the song catalog to preserve all events.

Dimension Tables
- users — one row per user with the latest known name, gender, and subscription level.
- songs — one row per song with title, release year, duration, and the artist foreign key.
- artists — one row per artist with name, location, latitude, and longitude.
- time — one row per distinct songplay timestamp with hour, day, week, month, year, and weekday components extracted.

### dbt Testing Layer

Seventeen automated tests run across staging and marts:
- 4 tests on staging views — not_null on user_id, start_time, session_id, song_id
- 13 tests on marts — unique and not_null on every primary key, plus relationship tests enforcing referential integrity between songplays and time, songplays and users, songs and artists

## Data Flow Summary

    101 JSON files (71 songs, 30 events)
         |
         v
    S3 Bucket (IAM user, scoped profile)
         |
         v
    Snowflake RAW (VARIANT, 8,056 events, 71 songs, METADATA$FILENAME lineage)
         |
         v
    dbt STAGING views (typed parsing, page filter on events)
         |
         v
    dbt MARTS tables (users, songs, artists, time, songplays)
         |
         v
    17 automated tests, lineage graph, documentation
         |
         v
    6,820 songplays, 17-second full build
