-- =============================================================================
-- fct_songplays.sql
-- Songplays fact table: one row per NextSong event, enriched with the
-- matching song_id/artist_id looked up from the song catalog by matching
-- on song title + artist name + duration (there is no shared numeric key
-- between the log data and the song metadata, so a fuzzy-but-exact text/
-- duration match is the standard approach for this dataset).
-- =============================================================================

with events as (

    select * from {{ ref('stg_events') }}

),

songs as (

    select * from {{ ref('dim_songs') }}

),

artists as (

    select * from {{ ref('dim_artists') }}

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
