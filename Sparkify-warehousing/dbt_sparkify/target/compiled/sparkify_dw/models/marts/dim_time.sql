-- =============================================================================
-- dim_time.sql
-- Time dimension: one row per distinct songplay timestamp, broken into
-- calendar parts (hour/day/week/month/year/weekday) so analysts can group
-- fct_songplays by any time grain without repeating date-math in every query.
-- =============================================================================

with events as (

    select distinct event_timestamp from SPARKIFY_DB.ANALYTICS.stg_events
    -- A NULL timestamp would produce a garbage row of all-NULL parts below.
    where event_timestamp is not null

)

select
    -- The full timestamp acts as this dimension's natural/primary key and
    -- is what fct_songplays.start_time joins against.
    event_timestamp                          as start_time,
    extract(hour from event_timestamp)       as hour,
    extract(day from event_timestamp)        as day,
    extract(week from event_timestamp)       as week,
    extract(month from event_timestamp)      as month,
    extract(year from event_timestamp)       as year,
    -- dayname() returns Mon/Tue/... which is friendlier in BI tools than
    -- the raw 0-6 integer from dayofweek().
    dayname(event_timestamp)                 as weekday

from events