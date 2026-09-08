-- =============================================================================
-- songplays.sql
-- Songplays fact table: one row per NextSong event, enriched with the
-- matching song_id / artist_id from the song catalog.
--
-- Columns (per the ERD):
--   songplay_id int | start_time bigint | user_id int | level varchar
--   song_id varchar | artist_id varchar | session_id int
--   location varchar | user_agent varchar
--
-- The event log has no song_id, so the catalog is matched on
-- title + artist name + duration. This MUST be a LEFT JOIN: the song
-- metadata is only a sample subset of the full catalog, so an INNER JOIN
-- silently collapses the fact table from 6,820 plays to ~30.
-- =============================================================================

with events as (

    select * from {{ ref('staging_events') }}

),

songs as (

    select * from {{ ref('songs') }}

),

artists as (

    select * from {{ ref('artists') }}

),

-- Flatten songs + artists into one lookup keyed by exactly the fields the
-- event log carries: title, artist name, duration.
song_catalog as (

    select
        songs.song_id,
        songs.title,
        songs.duration,
        artists.artist_id,
        artists.name as artist_name

    from songs
    inner join artists
        on songs.artist_id = artists.artist_id

),

enriched as (

    select
        events.start_time,
        events.user_id,
        events.level,
        song_catalog.song_id,
        song_catalog.artist_id,
        events.session_id,
        events.location,
        events.user_agent

    from events
    -- LEFT JOIN keeps every play, matched or not. Unmatched plays get a
    -- null song_id / artist_id instead of being dropped.
    left join song_catalog
        on events.song_title = song_catalog.title
        and events.artist_name = song_catalog.artist_name
        -- Round to 2 decimals to absorb float storage differences between
        -- the event log and the song metadata.
        and round(events.duration, 2) = round(song_catalog.duration, 2)

)

select
    -- Integer surrogate key, ordered deterministically by the natural grain
    -- of a songplay (who played, in which session, at what exact time) so
    -- re-runs produce the same ids rather than reshuffling them.
    row_number() over (
        order by start_time, user_id, session_id
    )::int                                     as songplay_id,

    start_time,
    user_id,
    level,
    -- Foreign keys into songs / artists (null when there is no catalog match).
    song_id,
    artist_id,
    session_id,
    location,
    user_agent

from enriched
