create
or replace view nyc_311_dbscan_noise as

-- Create the clustering functon using the Window funciton syntax
select
    id,
    ST_ClusterDBSCAN(st_transform(geom, 3857), 30, 30) over () AS cid,
    geom
from
    nyc_311
where

    -- Find just the complaints with "noise" in the description
    -- and that are in zip code 10009
    st_intersects(
        geom,
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '10009'
        )
    )
    and complaint_type ilike '%noise%'