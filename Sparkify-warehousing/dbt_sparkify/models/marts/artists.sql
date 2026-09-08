-- =============================================================================
-- artists.sql
-- Artist dimension: one row per artist_id with name and location metadata.
-- Split out from staging_songs since one artist can have many songs.
--
-- Columns (per the ERD):
--   artist_id varchar | name varchar | location varchar
--   latitude float | longitude float
-- =============================================================================

with songs as (

    select * from {{ ref('staging_songs') }}

),

-- Deduplicate to one row per artist_id, since the same artist appears
-- across multiple song files (occasionally with differing metadata).
deduped as (

    select
        artist_id,
        name,
        location,
        latitude,
        longitude,
        row_number() over (
            partition by artist_id
            order by loaded_at desc
        ) as recency_rank

    from songs
    where artist_id is not null

)

select
    artist_id,
    name,
    location,
    latitude,
    longitude

from deduped
where recency_rank = 1
