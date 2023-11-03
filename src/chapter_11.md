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

## 11.2 Similarity search or twin areas

### 11.9

```sql
create table tree_similarity as 

-- Finds the count of all trees in each neighborhood
with a as (
    select
        count(t.*) as total_trees,
        n.neighborhood
    from
        nyc_2015_tree_census t
        join nyc_neighborhoods n on st_intersects(t.geom, n.geom)
    group by
        n.neighborhood
)

-- Finds the count of each type of tree in each neighborhood
select
    n.neighborhood,
    (
        count(t.*) filter (
            where
                t.spc_common ilike '%pine%'
        ) :: numeric / a.total_trees
    ) as pine,
    (
        count(t.*) filter (
            where
                t.spc_common ilike '%maple%'
        ) :: numeric / a.total_trees
    ) as maple,
    (
        count(t.*) filter (
            where
                t.spc_common ilike '%linden%'
        ) :: numeric / a.total_trees
    ) as linden,
    (
        count(t.*) filter (
            where
                t.spc_common ilike '%honeylocust%'
        ) :: numeric / a.total_trees
    ) as honeylocust,
    (
        count(t.*) filter (
            where
                t.spc_common ilike '%oak%'
        ) :: numeric / a.total_trees
    ) as oak

-- Joins the above data with data from the original CTE
from
    nyc_2015_tree_census t
    join nyc_neighborhoods n on st_intersects(t.geom, n.geom)
    join a using (neighborhood)
group by
    n.neighborhood,
    a.total_trees
```

### 11.10

```sql
with a as (
    select
        *
    from
        tree_similarity
    where
        neighborhood = 'Harlem'
)
select
    t.neighborhood,

    -- Here we subtract the values from our target neighborhood in table "t"
    -- which is Harlem, from the average values across the city
    t.pine - a.pine as pine_dif,
    t.maple - a.maple as maple_dif,
    t.oak - a.oak as oak_dif,
    t.linden - a.linden as linden_dif,
    t.honeylocust - a.honeylocust as honeylocust_dif
from
    tree_similarity t,
    a
where
    t.neighborhood != 'Harlem'
```

### 11.11

```sql
create table harlem_tree_similarity as with a as (
    select
        *
    from
        tree_similarity
    where
        neighborhood = 'Harlem'
),

-- A: Find the difference between Harlem and all other neighborhoods 
b as (
    select
        t.neighborhood,
        t.pine - a.pine as pine_dif,
        t.maple - a.maple as maple_dif,
        t.oak - a.oak as oak_dif,
        t.linden - a.linden as linden_dif,
        t.honeylocust - a.honeylocust as honeylocust_dif
    from
        tree_similarity t,
        a
    where
        t.neighborhood != 'Harlem'
),

-- B: Find the min and max values in each column and store it as an array 
c as (
    select
        array [min(pine_dif), max(pine_dif)] as pine,
        array [min(maple_dif), max(maple_dif)] as maple,
        array [min(oak_dif), max(oak_dif)] as oak,
        array [min(linden_dif), max(linden_dif)] as linden,
        array [min(honeylocust_dif), max(honeylocust_dif)] as honeylocust
    from
        b
),

-- C: Find the absolute value of each difference value, normalize the data, and subtract that value from 1 
d as (
    select
        b.neighborhood,
        1 - (abs(b.pine_dif) - c.pine [1]) / (c.pine [2] - c.pine [1]) as pine_norm,
        1 - (b.maple_dif - c.maple [1]) / (c.maple [2] - c.maple [1]) as maple_norm,
        1 - (b.oak_dif - c.oak [1]) / (c.oak [2] - c.oak [1]) as oak_norm,
        1 - (b.linden_dif - c.linden [1]) / (c.linden [2] - c.linden [1]) as linden_norm,
        1 - (b.honeylocust_dif - c.honeylocust [1]) / (c.honeylocust [2] - c.honeylocust [1]) as honeylocust_norm
    from
        b,
        c
) 

-- D: Add up and divide the values 
select
    neighborhood,
    (
        pine_norm + maple_norm + oak_norm + linden_norm + honeylocust_norm
    ) / 5 as final
from
    d
order by
    2 desc
```

### 11.12

```sql
create table harlem_tree_similarity_geo as
select
    s.*,
    h.geom
from
    harlem_tree_similarity s
    join nyc_hoods h using (neighborhood)
```

## 11.3 Suitability or composite score

### 11.13

```sql
alter table
    nyc_2015_tree_census
add
    column h3 text
```

### 11.14

```sql
update
    nyc_2015_tree_census
set
    h3 = h3_lat_lng_to_cell(geom, 10)
```

### 11.15

```sql
create table nyc_bgs_h3s as
select
    geoid,
    h3_polygon_to_cells(geom, 10)
from
    nys_2021_census_block_groups
where
    left(geoid, 5) in ('36061', '36005', '36047', '36081', '36085')
```

### 11.16

```sql
select
    geoid,
    count(*)
from
    nyc_bgs_h3s
group by
    geoid
order by
    count(*) desc
limit
    5
```

### 11.26

```sql
-- Get the count of cells in each block group
with a as (
    select
        geoid,
        count(*) as count
    from
        nyc_bgs_h3s
    group by
        geoid
    order by
        count(*) desc
),

-- Join the total population to each H3 cell
b as (
    select
        h3.geoid,
        h3.h3_polygon_to_cells as h3,
        c.population as pop
    from
        nyc_bgs_h3s h3
        join nys_2021_census_block_groups c on h3.geoid = c.geoid
),

-- Find the proportional population by dividing the total
-- population by the H3 cell count per block group
c as (
    select
        b.pop :: numeric / a.count :: numeric as pop,
        b.h3,
        b.geoid
    from
        b
        join a using (geoid)
),

-- Find the scaled values for each target data point
d as (
    select
        c.*,
        abs(70000 - bgs.income) as income,
        abs(35 - bgs.age) as age
    from
        c
        join nys_2021_census_block_groups bgs using (geoid)
),

-- Get the tree count in each cell
e as (
    select
        d.h3,
        count(t.ogc_fid) as trees
    from
        d
        join nyc_2015_tree_census t on d.h3 :: text = t.h3
    group by
        d.h3
),

-- Add the min and max values for each data point to an array
f as (
    select
        array [min(trees), max(trees)] as trees_s,
        array [min(pop), max(pop)] as pop_s,
        array [min(income), max(income)] as income_s,
        array [min(age), max(age)] as age_s
    from
        e
        join d on d.h3 = e.h3
),

-- Join the two previous CTEs together
g as (
    select
        e.trees,
        d.age,
        d.income,
        d.pop,
        d.h3
    from
        d
        join e on d.h3 = e.h3
),

-- Calculate the 0 to 1 index
h as (
    select
        g.h3,
        (
            (g.trees :: numeric - f.trees_s [1]) /(f.trees_s [2] - f.trees_s [1])
        ) as trees_i,
        1 - ((g.age - f.age_s [1]) /(f.age_s [2] - f.age_s [1])) as age_i,
        1 - (
            (g.income - f.income_s [1]) /(f.income_s [2] - f.income_s [1])
        ) as income_i,
        ((g.pop - f.pop_s [1]) /(f.pop_s [2] - f.pop_s [1])) as pop_i
    from
        g,
        f
)

-- Add up to find the final index value
select
    *,
    trees_i + age_i + income_i + pop_i
from
    h
```

## 11.4 Mergers and acquisitions

### 11.27

```sql
create table pharmacy_stats as
select
    p.id,
    p.amenity,
    p.brand,
    p.name,
    p.geom,

    -- Add a buffer of 800 meters for later use
    st_transform(st_buffer(st_transform(p.geom, 3857), 800), 4326) as buffer,

    -- Get the total proportional population for each buffer 
    sum(
        bgs.population * (
            st_area(
                st_intersection(
                    st_transform(st_buffer(st_transform(p.geom, 3857), 800), 4326),
                    bgs.geom
                )
            ) / st_area(bgs.geom)
        )
    ) as pop
from
    nyc_pharmacies p
    join nyc_2021_census_block_groups bgs on st_intersects(p.geom, st_transform(bgs.geom, 4326))

-- Get just the stores for CVS and Duane Reade
where
    p.name ilike '%duane%'
    or p.name ilike '%cvs%'
group by
    p.id,
    p.amenity,
    p.brand,
    p.name,
    p.geom
```

### 11.28

```sql
select
    *
from
    nyc_pharmacies
where
    name ilike '%duane%'
    or name ilike '%cvs%'
```

### 11.29

```sql
-- CTE with all Duane Reade locations 
with dr as (
    select
        id,
        amenity,
        brand,
        name,
        geom,
        st_transform(geom, 3857) as geom_3857
    from
        nyc_pharmacies
    where
        name ilike '%duane%'
),

-- CTE with all CVS locations 
cvs as (
    select
        id,
        amenity,
        brand,
        name,
        geom,
        st_transform(geom, 3857) as geom_3857
    from
        nyc_pharmacies
    where
        name ilike '%cvs%'
),

-- Find all Duane Reade locations within 200 meters of a CVS
remove_nearest as (
    select
        dr.*
    from
        dr,
        cvs
    where
        st_dwithin(dr.geom_3857, cvs.geom_3857, 200)
)
select
    count(*)
from
    remove_nearest
```

### 11.30

```sql
with dr as (
    select
        *
    from
        pharmacy_stats
    where
        name ilike '%duane%'
)
select
    dr.*,

    -- Find the area of overlap between the two buffer groups
    st_area(
        st_intersection(pharmacy_stats.buffer, dr.buffer)
    ) / st_area(dr.buffer)
from
    dr
    join pharmacy_stats on st_intersects(dr.buffer, pharmacy_stats.buffer)
where

    -- Find the number of pharmacies that have an overlap greater than 75%
    st_area(
        st_intersection(pharmacy_stats.buffer, dr.buffer)
    ) / st_area(dr.buffer) >.75
    and pharmacy_stats.name ilike '%cvs%'
```

### 11.31

```sql
with a as (
    select

        -- Union all buffers to find the "before" scenario total area
        st_union(
            st_transform(st_buffer(st_transform(p.geom, 3857), 800), 4326)
        ) as buffer,
        st_area(
            st_union(st_buffer(st_transform(p.geom, 3857), 800))
        ) as area
    from
        nyc_pharmacies p
        join nyc_2021_census_block_groups bgs on st_intersects(
            st_transform(st_buffer(st_transform(p.geom, 3857), 800), 4326),
            st_transform(bgs.geom, 4326)
        )
    where
        p.name ilike '%duane%'
        or p.name ilike '%cvs%'
)
select
    a.*,

    -- Find the total populatino of all combined buffers
    sum(
        bgs.population * (
            st_area(st_intersection(a.buffer, bgs.geom)) / st_area(bgs.geom)
        )
    ) as pop
from
    a
    join nyc_2021_census_block_groups bgs on st_intersects(a.buffer, st_transform(bgs.geom, 4326))
group by
    1,
    2
```

### 11.32

```sql
create table duane_reade_ids as with overlap as (
    with dr as (
        select
            *
        from
            pharmacy_stats
        where
            name ilike '%duane%'
    )

    -- Find all the Duane Reade locations that have an overlap of over 75%
    select
        dr.id
    from
        dr
        join pharmacy_stats on st_intersects(dr.buffer, pharmacy_stats.buffer)
    where
        st_area(
            st_intersection(pharmacy_stats.buffer, dr.buffer)
        ) / st_area(dr.buffer) >.75
        and pharmacy_stats.name ilike '%cvs%'
),

-- Select all Duane Reade stores
dr as (
    select
        id,
        amenity,
        brand,
        name,
        geom,
        st_transform(geom, 3857) as geom_3857
    from
        nyc_pharmacies
    where
        name ilike '%duane%'
),

-- Select all CVS stores
cvs as (
    select
        id,
        amenity,
        brand,
        name,
        geom,
        st_transform(geom, 3857) as geom_3857
    from
        nyc_pharmacies
    where
        name ilike '%cvs%'
),

-- Remove all the Duane Reade locations within 200 meters of a CVS
remove_nearest as (
    select
        dr.id
    from
        dr,
        cvs
    where
        st_dwithin(dr.geom_3857, cvs.geom_3857, 200)
)
select
    id
from
    remove_nearest
union
select
    id
from
    overlap
```

### 11.33

```sql
-- We run the same query but we remove IDs not in the table we just created
with p as (
    select
        *
    from
        nyc_pharmacies
    where
        id not in (
            select
                id
            from
                duane_reade_ids
        )
),
a as (
    select
        st_union(
            st_transform(st_buffer(st_transform(p.geom, 3857), 800), 4326)
        ) as buffer,
        st_area(
            st_union(st_buffer(st_transform(p.geom, 3857), 800))
        ) as area
    from
        nyc_pharmacies p
        join nyc_2021_census_block_groups bgs on st_intersects(
            st_transform(st_buffer(st_transform(p.geom, 3857), 800), 4326),
            st_transform(bgs.geom, 4326)
        )
    where
        p.name ilike '%duane%'
        or p.name ilike '%cvs%'
)
select
    a.*,
    sum(
        bgs.population * (
            st_area(st_intersection(a.buffer, bgs.geom)) / st_area(bgs.geom)
        )
    ) as pop
from
    a
    join nyc_2021_census_block_groups bgs on st_intersects(a.buffer, st_transform(bgs.geom, 4326))
group by
    1,
    2
```