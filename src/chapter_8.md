# 8 - Spatial relationships

## 8.2 Ways to use spatial relationship functions

### 8.1

```sql
select
    ogc_fid,
    trip_distance,
    total_amount,
    
    -- ST_Intersects will return a boolean in a column
    st_intersects(

        -- First geometry is at the pickup location using the buildpoint function
        buildpoint(
            pickup_longitude :: numeric,
            pickup_latitude :: numeric,
            4326
        ),

        -- This selects the geometry for the West Village
        (
            select
                geom
            from
                nyc_neighborhoods
            where
                neighborhood = 'West Village'
        )
    )
from
    nyc_yellow_taxi_0601_0615_2016
order by
    pickup_datetime asc
limit
    10
```

### 8.1

```sql

```

### 8.2

```sql
select
    ogc_fid,
    trip_distance,
    total_amount
from
    nyc_yellow_taxi_0601_0615_2016
where

    -- Using ST_Intersects in the WHERE clause
    st_intersects(

        -- Using ST_Intersects in the WHERE clause, first with the pick up point
        buildpoint(
            pickup_longitude :: numeric,
            pickup_latitude :: numeric,
            4326
        ),

        -- Selecting the geometry for the West Village
        (
            select
                geom
            from
                nyc_neighborhoods
            where
                neighborhood = 'West Village'
        )
    )
order by
    pickup_datetime asc
limit
    10
```

### 8.3

```sql
alter table
    nyc_yellow_taxi_0601_0615_2016
add
    column pickup geometry,
add
    column dropoff geometry
```

### 8.4

```sql
update
    nyc_yellow_taxi_0601_0615_2016
set
    pickup = st_setsrid(
        st_makepoint(pickup_longitude, pickup_latitude),
        4326
    ),
    dropoff = st_setsrid(
        st_makepoint(pickup_longitude, pickup_latitude),
        4326
    )
```

### 8.5

```sql
select
    ogc_fid,
    trip_distance,
    total_amount
from
    nyc_yellow_taxi_0601_0615_2016
where
    st_intersects(
        pickup,
        (
            select
                geom
            from
                nyc_neighborhoods
            where
                neighborhood = 'West Village'
        )
    )
order by
    pickup_datetime asc
limit
    10
```

### 8.6

```sql
select
    a.ogc_fid,
    a.trip_distance,
    a.total_amount,
    st_intersects(a.pickup, b.geom)
from
    nyc_yellow_taxi_0601_0615_2016 a,
    nyc_neighborhoods b
where
    b.neighborhood = 'West Village'
order by
    a.pickup_datetime asc
limit
    100
```

### 8.7

```sql
select
    a.ogc_fid,
    a.trip_distance,
    a.total_amount
from
    nyc_yellow_taxi_0601_0615_2016 a

    -- Since ST_Intersects will return true or false
    -- we can use it to evaluate the join
    join nyc_neighborhoods b on st_intersects(a.pickup, b.geom)
where
    b.neighborhood = 'West Village'
order by
    a.pickup_datetime asc
limit
    10
```

### 8.8

```sql
select
    a.ogc_fid,
    a.trip_distance,
    a.total_amount,
    b.neighborhood
from
    nyc_yellow_taxi_0601_0615_2016 a
    join nyc_neighborhoods b on st_intersects(a.pickup, b.geom)
where
    b.neighborhood = 'West Village'
order by
    a.pickup_datetime asc
limit
    10
```

### 8.9

```sql
select

    -- Here we can aggregate other data that all falls within our 
    -- joined geometry data
    a.neighborhood,
    sum(b.total_amount) as sum_amount,
    avg(b.total_amount) as avg_amount
from
    nyc_neighborhoods a
    join nyc_yellow_taxi_0601_0615_2016 b on st_intersects(b.pickup, a.geom)
where 
	a.neighborhood = 'West Village'
group by
    a.neighborhood
limit
    5
```

### 8.10

```sql
with a as (
    select
        a.neighborhood,
        sum(b.total_amount) as sum_amount
    from
        nyc_neighborhoods a
        join nyc_yellow_taxi_0601_0615_2016 b on st_intersects(b.pickup, a.geom)
    where
        a.neighborhood = 'West Village'
    group by
        a.neighborhood
)
select
    a.sum_amount,
    b.*
from
    a
    join nyc_neighborhoods b using (neighborhood)
```

### 8.11

```sql
select
    zipcode,
    population,
    z.neighbor_sum
from
    nyc_zips a

    -- This join will join across to each row of data above
    -- but can also reference data from the outer query
    cross join lateral (
        select
            sum(population) as neighbor_sum
        from
            nyc_zips
        where
            st_intersects(geom, a.geom)
            and a.zipcode != zipcode
    ) z
```

## 8.3 Spatial relationship functions

### 8.12

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_contains(
        (
            select
                st_buffer(
                    buildpoint(-73.993584, 40.750580, 4326) :: geography,
                    200
                ) :: geometry
        ),
        geom
    )
```

### 8.13

```sql
select
    a.ogc_fid,
    a.name,
    st_centroid(st_transform(a.geom, 4326)),
    b.ogc_fid as b_id,
    st_transform(b.geom, 4326)
from
    nyc_building_footprints a
    join nyc_bike_routes b on st_crosses(a.geom, b.geom)
```

### 8.14

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_disjoint(
        (
            select
                st_buffer(
                    buildpoint(-74.002222, 40.733889, 4326) :: geography,
                    200
                ) :: geometry
        ),
        geom
    )
order by
    st_distance(
        (
            select
                st_buffer(
                    buildpoint(-74.002222, 40.733889, 4326) :: geography,
                    200
                ) :: geometry
        ),
        geom
    ) asc
limit
    200
```

### 8.15

```sql
select
    st_geomfromtext(
        'GEOMETRYCOLLECTION(LINESTRING(0 0, 3 3), POLYGON((0 0, 0 1, 1 1, 1 0, 0 0)))'
    ) as geom,
    st_overlaps(
        st_geomfromtext('LINESTRING(0 0, 0 3)'),
        st_geomfromtext('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))')
    )
```

### 8.16

```sql
select
    st_geomfromtext(
        'GEOMETRYCOLLECTION(POLYGON((1 0, 1 1, 1 2, 0 2, 1 0)), POLYGON((0 0, 0 1, 1 1, 1 0, 0 0)))'
    ) as geom,
    st_overlaps(
        st_geomfromtext('POLYGON((1 0, 1 1, 1 2, 0 2, 1 0))'),
        st_geomfromtext('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))')
    )
```

### 8.17

```sql
select
    st_geomfromtext(
        'GEOMETRYCOLLECTION(LINESTRING(1 0, 1 1, 0 1, 0 0), LINESTRING(2 1, 1 1, 0 1, 1 2))'
    ) as geom,
    st_overlaps(
        st_geomfromtext('LINESTRING(1 0, 1 1, 0 1, 0 0)'),
        st_geomfromtext('LINESTRING(2 1, 1 1, 0 1, 1 2)')
    )
```

### 8.18

```sql
select
    *
from
    nyc_zips
where
    st_touches(
        geom,
        (
            select
                geom
            from
                nyc_zips
            where
                zipcode = '10009'
        )
    )
```



### 8.19

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_within(
        geom,
        (
            select
                st_buffer(
                    buildpoint(-74.002222, 40.733889, 4326) :: geography,
                    200
                ) :: geometry
        )
    )
```

## 8.4 Distance Relationship Functions

### 8.20

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_intersects(
        geom,
        (
            select
                st_buffer(
                    buildpoint(-74.002222, 40.733889, 4326) :: geography,
                    200
                ) :: geometry
        )
    )
```

### 8.21

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_intersects(
        geom,
        (
            select
                st_buffer(
                    buildpoint(-74.002222, 40.733889, 4326) :: geography,
                    10000
                ) :: geometry
        )
    )
```

### 8.22

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_dwithin(
        st_transform(geom, 3857),
        buildpoint(-74.002222, 40.733889, 3857),
        200
    )
```

### 8.23

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_dwithin(
        st_transform(geom, 3857),
        st_transform(
            st_setsrid(st_makepoint(-74.002222, 40.733889), 4326),
            3857
        ),
        200
    )
```

### 8.24

```sql
alter table
    nyc_building_footprints
add
    column geom_3857 geometry;

update
    nyc_building_footprints
set
    geom_3857 = st_transform(geom, 3857);
```

### 8.25

```sql
select
    name,
    geom
from
    nyc_building_footprints
where
    st_dwithin(
        geom_3857,
        st_transform(
            st_setsrid(st_makepoint(-74.002222, 40.733889), 4326),
            3857
        ),
        200
    )
```

### 8.26

```sql
with a as (
    select
        st_transform(
            st_setsrid(st_makepoint(-74.002222, 40.733889), 4326),
            3857
        ) as geo
)
select
    name,
    geom
from
    nyc_building_footprints,
    a
where
    st_dwithin(geom_3857, a.geo, 200)
```

### 8.27

```sql
create index geom_3857_idx on 
nyc_building_footprints using gist(geom_3857)
```

### 8.28

```sql
with a as (
    select
        st_transform(
            st_setsrid(st_makepoint(-74.002222, 40.733889), 4326),
            3857
        ) as geo
)
select
    name,
    geom
from
    nyc_building_footprints,
    a
where
    st_dwithin(
        geom_3857,
        (
            select
                geo
            from
                a
        ),
        10000
    )
```

## 8.5 Spatial Joins

### 8.29

```sql
select
    a.ogc_fid,
    a.health,
    a.spc_common,
    b.neighborhood
from
    nyc_2015_tree_census a,
    nyc_neighborhoods b
where
    st_intersects(a.geom, b.geom)
    and a.spc_common ilike '%maple%'
```

### 8.30

```sql
select
    a.ogc_fid,
    a.health,
    a.spc_common,
    b.neighborhood
from
    nyc_2015_tree_census a
    join nyc_neighborhoods b on st_intersects(a.geom, b.geom)
    and a.spc_common ilike '%maple%'
```

### 8.31

```sql
create table nyc_2010_neighborhoods_subdivide as
select
    st_subdivide(geom) as geom,
    neighborhood
from
    nyc_neighborhoods
```

### 8.32

```sql
with trees as (
        select
            ogc_fid,
            health,
            spc_common,
            geom
        from
            nyc_2015_tree_census
        where
            spc_common ilike '%maple%'
    )
select
    trees.ogc_fid,
    trees.health,
    trees.spc_common,
    b.neighborhood
from
    trees
    join nyc_neighborhoods_subdivide b on st_intersects(trees.geom, b.geom)
```

### 8.33

```sql
create index nyc_neighborhoods_subdivide_geom_idx 
n nyc_neighborhoods_subdivide using gist(geom)
```

### 8.34

```sql
cluster nyc_neighborhoods_subdivide using nyc_neighborhoods_subdivide_geom_idx;

cluster nyc_2015_tree_census using nyc_2015_tree_census_geom_geom_idx;
```

### 8.35

```sql
select
    count(a.ogc_fid) filter (
        where
            a.spc_common ilike '%maple%'
    ) :: numeric / count(a.ogc_fid) :: numeric as percent_trees,
    count(a.ogc_fid) filter (
        where
            a.spc_common ilike '%maple%'
    ) as count_maples,
    b.neighborhood
from
    nyc_2015_tree_census a
    join nyc_neighborhoods_subdivide b on st_intersects(a.geom, b.geom)
group by
    b.neighborhood
```

## 8.6 Overlay Functions

### 8.36

```sql
select
    st_difference(a.geom, st_transform(b.geom, 4326)) as geom
from
    nyc_neighborhoods a,
    nyc_zips b
where
    b.zipcode = '10014'
    and a.neighborhood = 'West Village'
```

### 8.37

```sql
select
    st_intersection(a.geom, st_transform(b.geom, 4326)) as geom
from
    nyc_neighborhoods a,
    nyc_zips b
where
    b.zipcode = '10003'
    and a.neighborhood = 'Gramercy'
```

### 8.38

```sql
select
    st_intersection(a.geom, st_transform(b.geom, 4326)) as geom
from
    nyc_neighborhoods a,
    nyc_zips b
where
    b.zipcode = '10003'
    and a.neighborhood = 'Gramercy'
union
select
    geom
from
    nyc_neighborhoods
where
    neighborhood = 'Gramercy'
union
select
    st_transform(geom, 4326)
from
    nyc_zips
where
    zipcode = '10003'
```

### 8.39

```sql
-- Query all the street segments between W 39 ST and BANJ ST
with a as (
    select
        st_union(geom) as geom
    from
        nyc_bike_routes
    where
        fromstreet IN ('W HOUSTON ST', 'BANK ST')
        or tostreet IN ('BANK ST', 'W 39 ST', 'W HOUSTON ST')
)
select
    st_split(
        -- Select the geometgry for the West Village
        (
            select
                st_transform(geom, 4326)
            from
                nyc_neighborhoods
            where
                neighborhood = 'West Village'
        ),
        
        -- Split it with our geometry in our CTE above
        (
            select
                geom
            from
                a
        )
    )
```

### 8.40

```sql
select
    st_subdivide(st_transform(geom, 4326), 50) as geom
from
    nyc_neighborhoods
where
    neighborhood = 'West Village'
```

### 8.41

```sql
select
    st_union(geom) as geom
from
    nyc_neighborhoods
where
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
```

## 8.7 Cluster Functions

### 8.42

```sql
alter table
    nyc_311
add
    column geom geometry;

update
    nyc_311
set
    geom = buildpoint(longitude, latitude, 4326);
```

### 8.43

```sql
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
```

### 8.44

```sql
create
or replace view nyc_311_kmeans_noise as

-- Create the clustering functon using the Window funciton syntax
select
    id,
    ST_ClusterKMeans(st_transform(geom, 3857), 7, 1609) over () AS cid,
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
```

### 8.45

```sql
create table nyc_311_clusterwithin_noise as 

-- Find the 311 calls in the 10009 zip code
with a as (
    select
        geom
    from
        nyc_311
    where
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
),

-- In CTE "b", we have to unnest the results since it returns
-- geometries in an array
b as (
    select
        st_transform(
            unnest(ST_ClusterWithin(st_transform(geom, 3857), 25)),
            4326
        ) AS geom
    from
        a
)

-- row_number() over() creates an id for each row starting at 1
select
    row_number() over() as id,
    geom
from
    b
```

## 8.8 Special Operators

### 8.46

```sql
select
    zipcode,
    st_transform(geom, 4326)
from
    nyc_zips
where
    -- Finds all of the zip codes that intersect the bounding box
    -- of the East Village
    st_transform(geom, 4326) && (
        select
            geom
        from
            nyc_2010_neighborhoods
        where
            ntaname = 'East Village'
    )
UNION

-- Query to show the East Village bounding box on the map using ST_Envelope
select
    'None' as zipcode,
    st_envelope(
        (
            select
                geom
            from
                nyc_2010_neighborhoods
            where
                ntaname = 'East Village'
        )
    )
```

### 8.47

```sql
select
    geom
from
    nyc_neighborhoods
where
    geom &< (
        select
            geom
        from
            nyc_neighborhoods
        where
            neighborhood = 'East Village'
    )
```

### 8.48

```sql
with ev as (
    select
        geom
    from
        nyc_neighborhoods
    where
        neighborhood = 'East Village'
),
ues as (
    select
        geom
    from
        nyc_neighborhoods
    where
        neighborhood = 'Upper East Side'
)
select
    ev.geom <-> ues.geom,
    st_distance(ev.geom, use.geom)
from
    ev,
    ues
```

### 8.49

```sql
with ev as (
    select
        geom :: geography
    from
        nyc_neighborhoods
    where
        neighborhood = 'East Village'
),
ues as (
    select
        geom :: geography
    from
        nyc_neighborhoods
    where
        neighborhood = 'Upper East Side'
)
select
    ev.geom <-> ues.geom as new_operator,
    st_distance(ev.geom, ues.geom)
from
    ev,
    ues
```