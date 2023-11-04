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