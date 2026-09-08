-- =============================================================================
-- time.sql
-- Time dimension: one row per distinct songplay timestamp, broken into
-- calendar parts so analysts can group songplays by any grain without
-- repeating date math in every query.
--
-- Columns (per the ERD):
--   start_time bigint | hour int | day int | week int
--   month int | year int | weekday int
--
-- start_time stays the raw epoch-millisecond bigint so it joins directly
-- to songplays.start_time.
-- =============================================================================

with events as (

    select distinct
        start_time,
        event_timestamp

    from {{ ref('staging_events') }}
    -- A null timestamp would produce a row of all-null calendar parts.
    where start_time is not null

)

select
    -- Natural/primary key of this dimension.
    start_time,
    extract(hour    from event_timestamp)::int as hour,
    extract(day     from event_timestamp)::int as day,
    extract(week    from event_timestamp)::int as week,
    extract(month   from event_timestamp)::int as month,
    extract(year    from event_timestamp)::int as year,
    -- dayofweek() returns 0-6 (Sunday = 0), matching the int type in the ERD.
    dayofweek(event_timestamp)::int            as weekday

from events
