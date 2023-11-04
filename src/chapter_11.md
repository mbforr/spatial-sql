# 11 - Suitability analysis

## 11.1 Market expansion potential

### 11.1

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker dbname=gis port=25432" nyc_pharmacies.geojson \
-nln nyc_pharmacies -lco GEOMETRY_NAME=geom
```

### 11.2

```sql
```

### 11.8

```sql
-- Selects necessary data for Duane Reade locations
with a as (
    select
        id,
        amenity,
        brand,
        name,
        geom
    from
        nyc_pharmacies
    where
        name ilike '%duane%'
),

-- Spatially join the Duane Reade stores to neighborhoods and adds neighborhood names
b as (
    select
        a.*,
        b.neighborhood
    from
        a
        join nyc_neighborhoods b on st_intersects(a.geom, b.geom)
),

-- Creates a buffer for each store
c as (
    select
        id,
        st_buffer(st_transform(geom, 3857), 800) as buffer,
        neighborhood
    from
        b
),

-- Union the buffers together by neighborhood
d as (
    select
        st_transform(st_union(buffer), 4326) as geom,
        neighborhood
    from
        c
    group by
        neighborhood
),

-- Caluclates the proportional population for each group of buffers
-- and also the area of the groupped buffers
e as (
    select
        d.*,
        sum(
            bgs.population * (
                st_area(st_intersection(d.geom, bgs.geom)) / st_area(bgs.geom)
            )
        ) as pop,
        st_area(st_transform(d.geom, 3857)) as area
    from
        d
        join nys_2021_census_block_groups bgs on st_intersects(bgs.geom, d.geom)
    group by
        d.geom,
        d.neighborhood
)

-- Calculates the population density
select
    neighborhood,
    pop / area as potential
from
    e
order by
    pop / area desc
```




