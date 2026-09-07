
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
  );

