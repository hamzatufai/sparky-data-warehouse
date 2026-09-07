-- =============================================================================
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