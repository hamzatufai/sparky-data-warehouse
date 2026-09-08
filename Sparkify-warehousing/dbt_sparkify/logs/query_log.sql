-- created_at: 2026-09-08T04:31:10.626037800+00:00
-- finished_at: 2026-09-08T04:31:11.687208600+00:00
-- elapsed: 1.1s
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_staging_songs_song_id.68b9c36af3
-- query_id: 01c6ed0f-0303-026e-001d-aac3004f5902
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select song_id
from SPARKIFY_DB.STAGING.staging_songs
where song_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_staging_songs_song_id.68b9c36af3", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:10.626030100+00:00
-- finished_at: 2026-09-08T04:31:11.687728900+00:00
-- elapsed: 1.1s
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_songplays_songplay_id.154fe219c2
-- query_id: 01c6ed0f-0303-0934-001d-aac3004f062a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select songplay_id
from SPARKIFY_DB.MARTS.songplays
where songplay_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_songplays_songplay_id.154fe219c2", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:11.336260300+00:00
-- finished_at: 2026-09-08T04:31:11.829189600+00:00
-- elapsed: 492ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_users_user_id.fa10ab166c
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb58e
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_id
from SPARKIFY_DB.MARTS.users
where user_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_users_user_id.fa10ab166c", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:11.361247100+00:00
-- finished_at: 2026-09-08T04:31:11.856389200+00:00
-- elapsed: 495ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_staging_events_user_id.aa8c96934d
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb592
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_id
from SPARKIFY_DB.STAGING.staging_events
where user_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_staging_events_user_id.aa8c96934d", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:11.728505400+00:00
-- finished_at: 2026-09-08T04:31:12.137341300+00:00
-- elapsed: 408ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_artists_artist_id.d98fc86ba0
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb596
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select artist_id
from SPARKIFY_DB.MARTS.artists
where artist_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_artists_artist_id.d98fc86ba0", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:11.861601200+00:00
-- finished_at: 2026-09-08T04:31:12.194949100+00:00
-- elapsed: 333ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_staging_events_start_time.7d5774f705
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb59a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select start_time
from SPARKIFY_DB.STAGING.staging_events
where start_time is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_staging_events_start_time.7d5774f705", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:11.730672100+00:00
-- finished_at: 2026-09-08T04:31:12.682523900+00:00
-- elapsed: 951ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.unique_songplays_songplay_id.2f4c63b801
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb59e
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    songplay_id as unique_field,
    count(*) as n_records

from SPARKIFY_DB.MARTS.songplays
where songplay_id is not null
group by songplay_id
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.unique_songplays_songplay_id.2f4c63b801", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.159099+00:00
-- finished_at: 2026-09-08T04:31:12.686659800+00:00
-- elapsed: 527ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.unique_songs_song_id.d519ed7fcb
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb5a2
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    song_id as unique_field,
    count(*) as n_records

from SPARKIFY_DB.MARTS.songs
where song_id is not null
group by song_id
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.unique_songs_song_id.d519ed7fcb", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:11.882609100+00:00
-- finished_at: 2026-09-08T04:31:12.686724+00:00
-- elapsed: 804ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.unique_time_start_time.90fe1df25b
-- query_id: 01c6ed0f-0303-0934-001d-aac3004f062e
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    start_time as unique_field,
    count(*) as n_records

from SPARKIFY_DB.MARTS.time
where start_time is not null
group by start_time
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.unique_time_start_time.90fe1df25b", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.227674800+00:00
-- finished_at: 2026-09-08T04:31:12.746041600+00:00
-- elapsed: 518ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.unique_artists_artist_id.23eb205d2d
-- query_id: 01c6ed0f-0303-026e-001d-aac3004f5906
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    artist_id as unique_field,
    count(*) as n_records

from SPARKIFY_DB.MARTS.artists
where artist_id is not null
group by artist_id
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.unique_artists_artist_id.23eb205d2d", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.708782500+00:00
-- finished_at: 2026-09-08T04:31:12.978176700+00:00
-- elapsed: 269ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_songs_song_id.a1962cd985
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb5a6
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select song_id
from SPARKIFY_DB.MARTS.songs
where song_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_songs_song_id.a1962cd985", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.716471200+00:00
-- finished_at: 2026-09-08T04:31:13.079572900+00:00
-- elapsed: 363ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_time_start_time.7cd731e84d
-- query_id: 01c6ed0f-0303-0934-001d-aac3004f0632
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select start_time
from SPARKIFY_DB.MARTS.time
where start_time is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_time_start_time.7cd731e84d", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.764232300+00:00
-- finished_at: 2026-09-08T04:31:13.090867+00:00
-- elapsed: 326ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.unique_users_user_id.dff2f1fba5
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb5aa
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    user_id as unique_field,
    count(*) as n_records

from SPARKIFY_DB.MARTS.users
where user_id is not null
group by user_id
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.unique_users_user_id.dff2f1fba5", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.725187800+00:00
-- finished_at: 2026-09-08T04:31:13.203421500+00:00
-- elapsed: 478ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.not_null_staging_events_session_id.a4c08f1c8a
-- query_id: 01c6ed0f-0303-026e-001d-aac3004f590a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select session_id
from SPARKIFY_DB.STAGING.staging_events
where session_id is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.not_null_staging_events_session_id.a4c08f1c8a", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:13.100536800+00:00
-- finished_at: 2026-09-08T04:31:13.408780600+00:00
-- elapsed: 308ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.relationships_songplays_user_id__user_id__ref_users_.4aee5cc9c6
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb5b2
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select user_id as from_field
    from SPARKIFY_DB.MARTS.songplays
    where user_id is not null
),

parent as (
    select user_id as to_field
    from SPARKIFY_DB.MARTS.users
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.relationships_songplays_user_id__user_id__ref_users_.4aee5cc9c6", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:12.991395+00:00
-- finished_at: 2026-09-08T04:31:13.429495300+00:00
-- elapsed: 438ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.relationships_songplays_start_time__start_time__ref_time_.b4c9c25191
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb5ae
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select start_time as from_field
    from SPARKIFY_DB.MARTS.songplays
    where start_time is not null
),

parent as (
    select start_time as to_field
    from SPARKIFY_DB.MARTS.time
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.relationships_songplays_start_time__start_time__ref_time_.b4c9c25191", "profile_name": "sparkify_dw", "target_name": "dev"} */;
-- created_at: 2026-09-08T04:31:13.119596+00:00
-- finished_at: 2026-09-08T04:31:13.457526900+00:00
-- elapsed: 337ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.sparkify_dw.relationships_songs_artist_id__artist_id__ref_artists_.9c962afd61
-- query_id: 01c6ed0f-0303-0c33-001d-aac3004fb5b6
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select artist_id as from_field
    from SPARKIFY_DB.MARTS.songs
    where artist_id is not null
),

parent as (
    select artist_id as to_field
    from SPARKIFY_DB.MARTS.artists
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.sparkify_dw.relationships_songs_artist_id__artist_id__ref_artists_.9c962afd61", "profile_name": "sparkify_dw", "target_name": "dev"} */;
