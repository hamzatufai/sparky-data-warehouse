-- =============================================================================
-- songs.sql
-- Song dimension: one row per song_id with its title, release year,
-- duration, and a foreign key to the artists dimension.
--
-- Columns (per the ERD):
--   song_id varchar | title varchar | artist_id varchar
--   year int | duration float
-- =============================================================================

with songs as (

    select * from {{ ref('staging_songs') }}

),

-- Deduplicate in case the same song_id arrives in more than one source file.
deduped as (

    select
        song_id,
        title,
        artist_id,
        year,
        duration,
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
    -- Foreign key to artists.artist_id.
    artist_id,
    year,
    duration

from deduped
where recency_rank = 1
