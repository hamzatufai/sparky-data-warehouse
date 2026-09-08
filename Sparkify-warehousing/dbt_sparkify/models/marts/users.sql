-- =============================================================================
-- users.sql
-- User dimension: one row per user_id with their most recent known
-- name / gender / subscription level.
--
-- Columns (per the ERD):
--   user_id int | first_name varchar | last_name varchar
--   gender varchar | level varchar
-- =============================================================================

with events as (

    select * from {{ ref('staging_events') }}

),

-- A user appears once per event and their `level` can change over time
-- (free -> paid), so rank their events newest-first and keep only the
-- latest row to get current state.
ranked as (

    select
        user_id,
        first_name,
        last_name,
        gender,
        level,
        row_number() over (
            partition by user_id
            order by start_time desc
        ) as recency_rank

    from events
    -- Guard against logged-out events that slipped through with no user_id.
    where user_id is not null

)

select
    user_id,
    first_name,
    last_name,
    gender,
    level

from ranked
where recency_rank = 1
