
  
    



create or replace transient  table SPARKIFY_DB.ANALYTICS.dim_artists
    
    
    
    
    as (-- =============================================================================
-- dim_artists.sql
-- Artist dimension: one row per unique artist_id with name and location
-- metadata. Split out from stg_songs since one artist can have many songs.
-- =============================================================================

with songs as (

    select * from SPARKIFY_DB.ANALYTICS.stg_songs

),

-- Deduplicate to one row per artist_id, in case the same artist appears
-- across multiple song files with (rarely) slightly different metadata.
deduped as (

    select
        artist_id,
        artist_name,
        artist_location,
        artist_latitude,
        artist_longitude,
        row_number() over (
            partition by artist_id
            order by loaded_at desc
        ) as recency_rank

    from songs
    where artist_id is not null

)

select
    artist_id,
    artist_name,
    artist_location,
    artist_latitude,
    artist_longitude

from deduped
where recency_rank = 1
    )
;



  