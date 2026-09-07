
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
  );

