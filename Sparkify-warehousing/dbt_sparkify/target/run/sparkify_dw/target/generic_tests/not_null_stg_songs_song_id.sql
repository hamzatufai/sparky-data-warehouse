
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select song_id
from SPARKIFY_DB.ANALYTICS.stg_songs
where song_id is null



  
  
      
    ) dbt_internal_test