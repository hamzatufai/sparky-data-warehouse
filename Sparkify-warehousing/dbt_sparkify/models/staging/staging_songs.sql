-- =============================================================================
-- staging_songs.sql
-- Parses the raw VARIANT song-metadata payloads into typed columns.
-- One row per song/artist combination, later split into the songs and
-- artists dimensions in the marts layer.
-- =============================================================================

-- source() resolves to SPARKIFY_DB.RAW.RAW_SONGS via _staging__sources.yml.
with source as (

    select * from {{ source('sparkify_raw', 'raw_songs') }}

),

-- Extract and cast each field from the VARIANT payload.
parsed as (

    select
        -- Song attributes.
        raw_payload:song_id::varchar             as song_id,
        raw_payload:title::varchar               as title,
        raw_payload:year::int                    as year,
        raw_payload:duration::float              as duration,

        -- Artist attributes, kept alongside song attributes in this staging
        -- model since they arrive in the same JSON payload; the artists
        -- dimension deduplicates them at the marts layer.
        raw_payload:artist_id::varchar           as artist_id,
        raw_payload:artist_name::varchar         as name,
        raw_payload:artist_location::varchar     as location,
        raw_payload:artist_latitude::float       as latitude,
        raw_payload:artist_longitude::float      as longitude,

        -- Lineage columns carried through from the RAW table.
        source_file_name,
        loaded_at

    from source

)

select * from parsed
