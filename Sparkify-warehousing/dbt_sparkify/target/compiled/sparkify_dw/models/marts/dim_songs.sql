-- =============================================================================
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