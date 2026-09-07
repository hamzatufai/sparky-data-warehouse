-- created_at: 2026-09-07T11:35:26.813929100+00:00
-- finished_at: 2026-09-07T11:35:27.197578400+00:00
-- elapsed: 383ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c6e917-0303-0737-001d-aac3004eb566
-- desc: execute adapter call
show terse schemas in database SPARKIFY_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:27.338188300+00:00
-- finished_at: 2026-09-07T11:35:27.683815200+00:00
-- elapsed: 345ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.stg_events
-- query_id: 01c6e917-0303-0934-001d-aac3004f014a
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "SPARKIFY_DB"."ANALYTICS" LIMIT 10000;
-- created_at: 2026-09-07T11:35:27.700263300+00:00
-- finished_at: 2026-09-07T11:35:28.215815800+00:00
-- elapsed: 515ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.stg_events
-- query_id: 01c6e917-0303-0737-001d-aac3004eb56e
-- desc: execute adapter call
create or replace   view SPARKIFY_DB.ANALYTICS.stg_events
  
  
  
  
  as (
    -- =============================================================================
-- stg_events.sql
-- Parses the raw VARIANT event payloads into typed columns and filters down
-- to only "NextSong" events, since those are the only rows that represent
-- an actual song play (other page values are things like "Login", "Home").
-- Materialized as a VIEW (see dbt_project.yml) - cheap re-computation over
-- the RAW table, no duplicated storage.
-- =============================================================================

-- source() resolves to SPARKIFY_DB.RAW.RAW_EVENTS via _staging__sources.yml,
-- so this model never needs to hardcode the physical table location.
with source as (

    select * from SPARKIFY_DB.RAW.raw_events

),

-- Pull each field out of the VARIANT payload with the ':' path operator and
-- cast it to its proper type, since VARIANT fields are untyped by default.
parsed as (

    select
        -- User identifiers and profile attributes.
        raw_payload:userId::int                        as user_id,
        raw_payload:firstName::string                   as first_name,
        raw_payload:lastName::string                     as last_name,
        raw_payload:gender::string                       as gender,
        raw_payload:level::string                        as level,

        -- Session / event context.
        raw_payload:sessionId::int                       as session_id,
        raw_payload:itemInSession::int                    as item_in_session,
        raw_payload:page::string                          as page,
        raw_payload:auth::string                          as auth,
        raw_payload:method::string                        as method,
        raw_payload:status::int                           as status_code,
        raw_payload:location::string                      as location,
        raw_payload:userAgent::string                     as user_agent,

        -- Song-play specific attributes.
        raw_payload:song::string                          as song_title,
        raw_payload:artist::string                        as artist_name,
        raw_payload:length::float                         as duration_seconds,

        -- Timestamps arrive as epoch milliseconds; convert to a proper
        -- TIMESTAMP_NTZ so dbt_time / date functions work downstream.
        raw_payload:ts::bigint                            as event_ts_epoch_ms,
        to_timestamp_ntz(raw_payload:ts::bigint / 1000)   as event_timestamp,
        raw_payload:registration::bigint                  as registration_epoch_ms,

        -- Lineage columns carried through from the RAW table.
        source_file_name,
        loaded_at

    from source

)

-- Keep only actual song-play events. Every other `page` value (e.g.
-- "Home", "Login", "Logout", "Help") is navigation, not a play, and would
-- pollute fct_songplays if left in.
select *
from parsed
where page = 'NextSong'
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.stg_events", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:28.300711800+00:00
-- finished_at: 2026-09-07T11:35:29.444043+00:00
-- elapsed: 1.1s
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.dim_users
-- query_id: 01c6e917-0303-0737-001d-aac3004eb572
-- desc: execute adapter call
create or replace transient  table SPARKIFY_DB.ANALYTICS.dim_users
    
    
    
    
    as (-- =============================================================================
-- dim_users.sql
-- User dimension: one row per userId, capturing their most recent known
-- name/gender/subscription level. A user can appear many times in the event
-- log (once per action), and their `level` can change over time (free ->
-- paid), so we deduplicate down to their latest event.
-- =============================================================================

with events as (

    select * from SPARKIFY_DB.ANALYTICS.stg_events

),

-- Rank each user's events newest-first so row_number = 1 is their most
-- recent known state (name, gender, and subscription level).
ranked as (

    select
        user_id,
        first_name,
        last_name,
        gender,
        level,
        event_timestamp,
        row_number() over (
            partition by user_id
            order by event_timestamp desc
        ) as recency_rank

    from events
    -- Guard against events with a null/blank user_id (e.g. logged-out
    -- pageviews that still slipped through the page = 'NextSong' filter).
    where user_id is not null

)

select
    user_id,
    first_name,
    last_name,
    gender,
    -- Most recent subscription level - this is what current-state reporting
    -- (e.g. "how many paid users do we have today") should use.
    level as current_level

from ranked
-- Only keep each user's single most recent row.
where recency_rank = 1
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.dim_users", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:29.450034900+00:00
-- finished_at: 2026-09-07T11:35:29.778680400+00:00
-- elapsed: 328ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.stg_songs
-- query_id: 01c6e917-0303-0891-001d-aac3004df78e
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "SPARKIFY_DB"."ANALYTICS" LIMIT 10000;
-- created_at: 2026-09-07T11:35:29.797786+00:00
-- finished_at: 2026-09-07T11:35:30.258006500+00:00
-- elapsed: 460ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.stg_songs
-- query_id: 01c6e917-0303-026e-001d-aac3004a7eca
-- desc: execute adapter call
create or replace   view SPARKIFY_DB.ANALYTICS.stg_songs
  
  
  
  
  as (
    -- =============================================================================
-- stg_songs.sql
-- Parses the raw VARIANT song-metadata payloads into typed columns.
-- One row per song/artist combination, later split into dim_songs and
-- dim_artists in the marts layer.
-- =============================================================================

-- source() resolves to SPARKIFY_DB.RAW.RAW_SONGS via _staging__sources.yml.
with source as (

    select * from SPARKIFY_DB.RAW.raw_songs

),

-- Extract and cast each field from the VARIANT payload.
parsed as (

    select
        -- Song attributes.
        raw_payload:song_id::string          as song_id,
        raw_payload:title::string             as title,
        raw_payload:duration::float           as duration_seconds,
        -- year is stored as 0 for unknown release years in the source data;
        -- normalize 0 to NULL so downstream aggregations aren't skewed.
        nullif(raw_payload:year::int, 0)      as release_year,

        -- Artist attributes, kept alongside song attributes in this staging
        -- model since they arrive in the same JSON payload; dim_artists
        -- deduplicates them at the marts layer.
        raw_payload:artist_id::string         as artist_id,
        raw_payload:artist_name::string        as artist_name,
        raw_payload:artist_location::string    as artist_location,
        raw_payload:artist_latitude::float     as artist_latitude,
        raw_payload:artist_longitude::float    as artist_longitude,

        -- Lineage columns carried through from the RAW table.
        source_file_name,
        loaded_at

    from source

)

select * from parsed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.stg_songs", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:29.663972+00:00
-- finished_at: 2026-09-07T11:35:30.666764+00:00
-- elapsed: 1.0s
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.dim_time
-- query_id: 01c6e917-0303-0934-001d-aac3004f0152
-- desc: execute adapter call
create or replace transient  table SPARKIFY_DB.ANALYTICS.dim_time
    
    
    
    
    as (-- =============================================================================
-- dim_time.sql
-- Time dimension: one row per distinct songplay timestamp, broken into
-- calendar parts (hour/day/week/month/year/weekday) so analysts can group
-- fct_songplays by any time grain without repeating date-math in every query.
-- =============================================================================

with events as (

    select distinct event_timestamp from SPARKIFY_DB.ANALYTICS.stg_events
    -- A NULL timestamp would produce a garbage row of all-NULL parts below.
    where event_timestamp is not null

)

select
    -- The full timestamp acts as this dimension's natural/primary key and
    -- is what fct_songplays.start_time joins against.
    event_timestamp                          as start_time,
    extract(hour from event_timestamp)       as hour,
    extract(day from event_timestamp)        as day,
    extract(week from event_timestamp)       as week,
    extract(month from event_timestamp)      as month,
    extract(year from event_timestamp)       as year,
    -- dayname() returns Mon/Tue/... which is friendlier in BI tools than
    -- the raw 0-6 integer from dayofweek().
    dayname(event_timestamp)                 as weekday

from events
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.dim_time", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:30.285191600+00:00
-- finished_at: 2026-09-07T11:35:31.182865700+00:00
-- elapsed: 897ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.dim_artists
-- query_id: 01c6e917-0303-0737-001d-aac3004eb576
-- desc: execute adapter call
create or replace transient  table SPARKIFY_DB.ANALYTICS.dim_artists
    
    
    
    
    as (-- =============================================================================
-- dim_artists.sql
-- Artist dimension: one row per unique artist_id with name and location
-- metadata. Split out from stg_songs since one artist can have many songs.
-- =============================================================================

with songs as (

    select * from SPARKIFY_DB.ANALYTICS.stg_songs

),

-- Deduplicate to one row per artist_id, in case the same artist appears
-- across multiple song files with (rarely) slightly different metadata.
deduped as (

    select
        artist_id,
        artist_name,
        artist_location,
        artist_latitude,
        artist_longitude,
        row_number() over (
            partition by artist_id
            order by loaded_at desc
        ) as recency_rank

    from songs
    where artist_id is not null

)

select
    artist_id,
    artist_name,
    artist_location,
    artist_latitude,
    artist_longitude

from deduped
where recency_rank = 1
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.dim_artists", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:30.285182100+00:00
-- finished_at: 2026-09-07T11:35:31.265083200+00:00
-- elapsed: 979ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.dim_songs
-- query_id: 01c6e917-0303-0934-001d-aac3004f0156
-- desc: execute adapter call
create or replace transient  table SPARKIFY_DB.ANALYTICS.dim_songs
    
    
    
    
    as (-- =============================================================================
-- dim_songs.sql
-- Song dimension: one row per unique song_id with its title, duration,
-- release year, and a foreign key back to dim_artists.
-- =============================================================================

with songs as (

    select * from SPARKIFY_DB.ANALYTICS.stg_songs

),

-- Deduplicate defensively in case the same song_id appears in more than one
-- source file (e.g. re-processed/overlapping song_data exports).
deduped as (

    select
        song_id,
        title,
        artist_id,
        duration_seconds,
        release_year,
        row_number() over (
            partition by song_id
            order by loaded_at desc
        ) as recency_rank

    from songs
    where song_id is not null

)

select
    song_id,
    title,
    -- Foreign key to dim_artists.artist_id.
    artist_id,
    duration_seconds,
    release_year

from deduped
where recency_rank = 1
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.dim_songs", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-07T11:35:31.454762800+00:00
-- finished_at: 2026-09-07T11:35:32.923071400+00:00
-- elapsed: 1.5s
-- outcome: success
-- dialect: snowflake
-- node_id: model.sparkify_dw.fct_songplays
-- query_id: 01c6e917-0303-0891-001d-aac3004df796
-- desc: execute adapter call
create or replace transient  table SPARKIFY_DB.ANALYTICS.fct_songplays
    
    
    
    
    as (-- =============================================================================
-- fct_songplays.sql
-- Songplays fact table: one row per NextSong event, enriched with the
-- matching song_id/artist_id looked up from the song catalog by matching
-- on song title + artist name + duration (there is no shared numeric key
-- between the log data and the song metadata, so a fuzzy-but-exact text/
-- duration match is the standard approach for this dataset).
-- =============================================================================

with events as (

    select * from SPARKIFY_DB.ANALYTICS.stg_events

),

songs as (

    select * from SPARKIFY_DB.ANALYTICS.dim_songs

),

artists as (

    select * from SPARKIFY_DB.ANALYTICS.dim_artists

),

-- Join the song catalog (songs + artists) into a single lookup table keyed
-- by the same fields present in the event log: title, artist name, duration.
song_catalog as (

    select
        songs.song_id,
        songs.title,
        songs.duration_seconds,
        artists.artist_id,
        artists.artist_name

    from songs
    inner join artists
        on songs.artist_id = artists.artist_id

),

-- Left join events to the catalog so plays of songs NOT in our metadata
-- catalog are still kept in the fact table (with NULL song_id/artist_id)
-- rather than silently dropped.
enriched as (

    select
        events.user_id,
        events.session_id,
        events.level,
        events.location,
        events.user_agent,
        events.event_timestamp             as start_time,
        song_catalog.song_id,
        song_catalog.artist_id,
        events.song_title,
        events.artist_name

    from events
    left join song_catalog
        on events.song_title = song_catalog.title
        and events.artist_name = song_catalog.artist_name
        -- Match duration to 2 decimal places to absorb tiny floating-point
        -- differences between how the log and the song catalog store it.
        and round(events.duration_seconds, 2) = round(song_catalog.duration_seconds, 2)

)

select
    -- Deterministic surrogate key: hash of the natural grain of a songplay
    -- (who played what, in which session, at what exact time) so re-runs of
    -- this model are idempotent and don't mint new IDs for the same event.
    md5(
        coalesce(cast(user_id as string), '')       || '|' ||
        coalesce(cast(session_id as string), '')    || '|' ||
        coalesce(cast(start_time as string), '')
    )                                                as songplay_id,

    start_time,
    user_id,
    level,
    -- Foreign keys into dim_songs / dim_artists (NULL when no catalog match).
    song_id,
    artist_id,
    session_id,
    location,
    user_agent

from enriched
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.sparkify_dw.fct_songplays", "profile_name": "sparkify_dw", "target_name": "dev"} */;
