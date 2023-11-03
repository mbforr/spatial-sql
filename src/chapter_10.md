# 10 - Advanced spatial analytics

## 10.1 Spatial data enrichment or area weighted interpolation

### 10.1

```sh
ogrinfo ACS_2021_5YR_BG_36_NEW_YORK.gdb ACS_2021_5YR_BG_36_NEW_YORK -geom=YES -so
```

### Other import code

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker
dbname=gis port=25432" ACS_2021_5YR_BG_36_NEW_YORK.gdb \
-dialect sqlite -sql "select GEOID as geoid, b01001e1 as population, B01002e1 as age from X01_AGE_AND_SEX" \
-nln nys_2021_census_block_groups_pop -lco GEOMETRY_NAME=geom
```

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \ dbname=gis port=25432" ACS_2021_5YR_BG_36_NEW_YORK.gdb \
-dialect sqlite -sql "select GEOID as geoid, B19001e1 as income from X19_INCOME" \ 
-nln nys_2021_census_block_groups_income -lco GEOMETRY_NAME=geom
```

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \
dbname=gis port=25432" ACS_2021_5YR_BG_36_NEW_YORK.gdb \
-dialect sqlite -sql "select SHAPE as geom, GEOID as geoid from ACS_2021_5YR_BG_36_NEW_YORK" \
-nln nys_2021_census_block_groups_geom -lco GEOMETRY_NAME=geom
```

### 10.3

```sql
update nyc_neighborhoods set geom = st_makevalid(geom) where st_isvalid(geom) is false
```

### 10.4

```sql
select
    neighborhood,

    -- These are the values from the cross join lateral
    a.pop,
    a.count,
    a.avg
from
    nyc_neighborhoods
    cross join lateral (
        select

            -- This selects the sum of all the intersecting areas
            -- populations using the proportional overlap calculation
            sum(
                population * (
                    st_area(st_intersection(geom, nyc_neighborhoods.geom)) / st_area(geom)
                )
            ) as pop,
            count(*) as count,

            -- This selects the average area overlapping area
            -- of all the intersecting areas
            avg(
                (
                    st_area(st_intersection(nyc_neighborhoods.geom, geom)) / st_area(geom)
                )
            ) as avg
        from
            nys_2021_census_block_groups
        where
            left(geoid, 5) in ('36061', '36005', '36047', '36081', '36085')
            and st_intersects(nyc_neighborhoods.geom, geom)
    ) a
order by
    a.pop desc
```

## 10.2 Nearest neighbor in report format

### 10.5

```sh
ogr2ogr \
    - f PostgreSQL PG :"host=localhost user=docker password=docker \ 
    dbname=gis port=25432" Subway_Entrances.geojson \ 
    - nln nyc_subway_enterances - lco GEOMETRY_NAME = geom
```

### 10.6

```sql
select
    sw.name,
    sw.objectid,
    near.tree_id,
    near.spc_common,
    near.distance
from
    nyc_subway_enterances sw

    -- Since this is a cross join it will join to every possible combination
    -- Since we have a limit of 5 below, it will join it to each row in the
    -- main subway enterances table 5 times
    cross join lateral (
        select
            tree_id,
            spc_common,
            st_distance(sw.geom :: geography, geom :: geography) as distance
        from
            nyc_2015_tree_census
        order by
            sw.geom <-> geom
        limit
            5
    ) near 
```

### 10.7

```sql
select
    sw.name,
    sw.objectid,
    near.tree_id,
    near.spc_common,
    near.distance,
    near.ranking
from
    nyc_subway_enterances sw
    cross join lateral (
        select
            tree_id,
            spc_common,
            st_distance(sw.geom :: geography, geom :: geography) as distance,
            row_number() over() as ranking
        from
            nyc_2015_tree_census
        order by
            sw.geom <-> geom
        limit
            5
    ) near
limit
    50
```

### 10.8

```sql
select
    sw.name,
    sw.objectid,
    near.tree_id,
    near.spc_common,
    near.distance,
    rank() over(

        -- The partition will perform the ranking for each 
        -- subway enterance ID for the 5 matching trees linked
        -- to that station ID
        partition by sw.objectid

        -- The ranking will be ordered by the distance
        order by
            distance desc
    )
from
    nyc_subway_enterances sw
    cross join lateral (
        select
            tree_id,
            spc_common,
            st_distance(sw.geom :: geography, geom :: geography) as distance
        from
            nyc_2015_tree_census
        order by
            sw.geom <-> geom
        limit
            5
    ) near
limit
    50
```

## 10.3 Flat line of sight

### 10.9

```sh
ogr2ogr \ 
-f PostgreSQL PG:"host=localhost user=docker password=docker \
dbname=gis port=25432" planimetrics_2018_roofprints.json \ 
-nln denver_buildings -lco GEOMETRY_NAME=geom
```

### 10.10

```sql
select
    geom,
    bldg_heigh,
    ground_ele,
    gid
from
    denver_buildings
order by
    random()
limit
    2
```

### 10.11

```sql
with a as (
    select
        geom,
        bldg_heigh,
        ground_ele,
        gid
    from
        denver_buildings
    order by
        random()
    limit
        2
)
select

    -- This will create an array for the two buildings above.
    -- One below for the centroid
    array_agg(st_centroid(st_transform(geom, 4326))) as geom,

    -- One for the building height + ground height
    array_agg(bldg_heigh + ground_ele) as height,

    -- One for the building IDs
    array_agg(gid) as id
from
    a
```

### 10.1

```sql
with a as (
    select
        geom,
        bldg_heigh,
        ground_ele,
        gid
    from
        denver_buildings
    order by
        random()
    limit
        2
), bldgs as (
    select
        array_agg(st_centroid(st_transform(geom, 4326))) as geom,
        array_agg(bldg_heigh + ground_ele) as height,
        array_agg(gid) as id
    from
        a
),
line as (
    select

        -- Here we create a line between the two centroids
        -- using both the geometries in individual subqueries
        st_makeline(
            (
                select
                    geom [1]
                from
                    bldgs
            ),
            (
                select
                    geom [2]
                from
                    bldgs
            )
        )
)
select
    *
from
    line
```

### 10.13

```sql
with a as (
    select
        geom,
        bldg_heigh,
        ground_ele,
        gid
    from
        denver_buildings
    order by
        random()
    limit
        2
), bldgs as (
    select
        array_agg(st_centroid(st_transform(geom, 4326))) as geom,
        array_agg(bldg_heigh + ground_ele) as height,
        array_agg(gid) as id
    from
        a
),
line as (

    -- Here we use a simple select statement rather tha subqueries 
    -- like the previous step to grab the height column too
    select
        st_makeline(geom [1], geom [2]) as geom,
        height
    from
        bldgs
)
select

    -- This will return all the buildings higher than the line
    b.gid,
    b.bldg_heigh + b.ground_ele as height,
    st_transform(b.geom, 4326),
    line.height
from
    denver_buildings b
    join line on st_intersects(line.geom, st_transform(b.geom, 4326))
where

    -- This finds any building taller than either of our two buildings
    b.bldg_heigh + b.ground_ele < line.height [1]
    or b.bldg_heigh + b.ground_ele < line.height [2]
```

## 10.4 3D line of sight

### 10.14

```sql
alter table
    denver_buildings
add
    column geom_z geometry
```

### 10.15

```sql
update
    denver_buildings
set
    geom_z = st_force3d(

        -- First value is the building geometry in EPSG 4326
        st_transform(geom, 4326),

        -- This is our Z or height value, the building height 
        -- plus the ground elevation
        bldg_heigh + ground_ele
    )
```

### 10.16

```sql
-- Find our first building
with a as (
    select
        geom_z,
        gid
    from
        denver_buildings
    limit
        1 offset 100
),

-- Find a building with its ID and GeometryZ
-- within 2 kilometers
b as (
    select
        geom_z,
        gid
    from
        denver_buildings
    where
        st_dwithin(
            st_transform(geom, 3857),
            (
                select
                    st_transform(geom, 3857)
                from
                    a
            ),
            2000
        )
    limit
        1
), 

-- Use UNION to create a single table with matching columns
c as (
    select
        *
    from
        a
    union
    select
        *
    from
        b
),

-- Store the geometries and and IDs in arrays
bldgs as (
    select
        array_agg(st_centroid(geom_z)) as geom,
        array_agg(gid) as id
    from
        c
),

-- This query finds all the buildings within 3 kilometers of each building
denver as (
    select
        st_transform(geom, 3857) as geom,
        geom_z,
        gid
    from
        denver_buildings
    where
        st_dwithin(

            -- We union the two points and turn them back into 2D
            -- Geometries so we can run the query to find all 
            -- buildings with 3 kilometers one time
            st_union(
                (
                    select
                        st_force2d(st_transform(geom [1], 3857))
                    from
                        bldgs
                ),
                (
                    select
                        st_force2d(st_transform(geom [2], 3857))
                    from
                        bldgs
                )
            ),
            st_transform(geom, 3857),
            3000
        )
)
select
    d.gid,
    st_transform(d.geom, 4326) as geom
from
    denver d

    -- Now we can use our ST_3DIntersects funciton to find 
    -- all the buildings crossing our path
    join bldgs on st_3dintersects(

        -- The path can be built using the same ST_MakeLine
        -- function we have been using
        st_makeline(bldgs.geom [1], bldgs.geom [2]),
        d.geom_z
    )
```
## 10.5 Calculate polygons that share a border

### 10.17

```sql
create table nyc_2021_census_block_groups_morans_i as
select
    *
from
    nys_2021_census_block_groups
where
    left(geoid, 5) in ('36061', '36005', '36047', '36081', '36085')
    and population > 0
```

### 10.18

```sql
with a as (
    select
        *
    from
        nyc_2021_census_block_groups
    where
        geoid = '360470201002'
)
select
    bgs.geoid,

    -- Finds the number of points of the 
    -- portion of the border that intersects
    st_npoints(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        )
    ) as intersected_points,

    -- Finds the length of the 
    -- portion of the border that intersects 
    st_length(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        ) :: geography
    ) as length,
	geom
from
    nyc_2021_census_block_groups bgs
where
    st_intersects(
        (
            select
                geom
            from
                a
        ),
        bgs.geom
    )
    and bgs.geoid != (
        select
            geoid
        from
            a
    )
```

### 10.19

```sql
with a as (
    select
        *
    from
        nyc_2021_census_block_groups
    where
        geoid = '360470201002'
)
select
    bgs.*,
    st_npoints(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        )
    ) as intersected_points,
    st_length(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        ) :: geography
    ) as length,
    geom
from
    nyc_2021_census_block_groups bgs
where

    -- Only select polygons that have a border overlap 
    -- of 2 points or more
    st_npoints(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        )
    ) > 1
    and bgs.geoid != (
        select
            geoid
        from
            a
    )
```

### 10.20

```sql
with a as (
    select
        *
    from
        nyc_2021_census_block_groups
    where
        geoid = '360470201002'
)
select
    bgs.*,
    st_npoints(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        )
    ) as intersected_points,
    st_length(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        ) :: geography
    ) as length,
    geom
from
    nyc_2021_census_block_groups bgs
where

    -- Only select polygons that have a border overlap 
    -- of 100 meters or more
    st_length(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        ) :: geography
    ) > 100
    and bgs.geoid != (
        select
            geoid
        from
            a
    )
```

### 10.21

```sql
with a as (
    select
        *
    from
        nyc_2021_census_block_groups
    where
        geoid = '360470201002'
)
select
    bgs.geoid,
    geom,
    st_npoints(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        )
    ) as intersected_points,
    st_length(
        st_intersection(
            bgs.geom,
            (
                select
                    geom
                from
                    a
            )
        ) :: geography
    ) as length,
    (
        -- Finding the length of the shared border
        st_length(
            st_intersection(
                bgs.geom,
                (
                    select
                        geom
                    from
                        a
                )
            ) :: geography

        -- Dividing that by the perimiter of the source polygon
        ) / st_perimeter(
            (
                select
                    geom :: geography
                from
                    a
            )
        )
    ) as percent_of_source
from
    nyc_2021_census_block_groups bgs
where
    -- Finding touching polygons that share more than 25% of
    -- the source polygon's border
    (
        st_length(
            st_intersection(
                bgs.geom,
                (
                    select
                        geom
                    from
                        a
                )
            ) :: geography
        ) / st_perimeter(
            (
                select
                    geom :: geography
                from
                    a
            )
        )
    ) >.25
    and bgs.geoid != (
        select
            geoid
        from
            a
    )
```

## 10.6 Finding the most isolated feature

### 10.23

```sql
alter table
    nyc_building_footprints
add
    column h3 text
```

### 10.24

```sql
update
    nyc_building_footprints
set
    h3 = h3_lat_lng_to_cell(
        st_centroid(
            st_transform(geom, 4326)
        ), 10)
```

### 10.25

```sql
select
    bin,
    st_transform(geom, 4326) as geom
from
    nyc_building_footprints b
where

    -- Returns all the H3 cells that meet the condition in the subquery
    h3 in (
        select
            h3
        from
            nyc_building_footprints

        -- First we group the H3 cells to use the aggregate function
        group by
            h3

        -- This finds all the H3 cells that have an aggregate
        -- count greater than 1
        having
            count(*) = 1
    )
```

### 10.26

```sql
select
    bin,
    closest.distance,
    st_transform(geom, 4326) as geom
from
    nyc_building_footprints b
    cross join lateral (
        select

            -- Finding the distance to the nearest building in meters
            st_distance(
                st_transform(geom, 3857),
                st_transform(b.geom, 3857)
            ) as distance
        from
            nyc_building_footprints

        -- This removes the ID of the building we want to analyze    
        where
            bin != b.bin
        order by
            geom <-> b.geom
        limit
            1
    ) closest
where
    h3 in (
        select
            h3
        from
            nyc_building_footprints
        group by
            h3
        having
            count(*) = 1
    )
order by
    closest.distance desc
```

### 10.27

```sql
select
    *
from
    nyc_building_footprints
where
    bin = '2127308'
```

## 10.7 Kernel density estimation (KDE)

### 10.35

```sql
create
or replace function st_kdensity(ids bigint [], geoms geometry []) 
returns table(id bigint, geom geometry, kdensity integer) as $$ declare mc geometry;

c integer;

k numeric;

begin mc := st_centroid(st_collect(geoms));

c := array_length(ids, 1);

k := sqrt(1 / ln(2));

return query with dist as (
    select
        t.gid,
        t.g,
        st_distance(t.g, mc) as distance
    from
        unnest(ids, geoms) as t(gid, g)
),
md as (
    select
        percentile_cont(0.5) within group (
            order by
                distance
        ) as median
    from
        dist
),
sd as (
    select
        sqrt(
            sum((st_x(g) - st_x(mc)) ^ 2) / c + sum((st_y(g) - st_y(mc)) ^ 2) / c
        ) as standard_distance
    from
        dist
),
sr as (
    select
        0.9 * least(sd.standard_distance, k * md.median) * c ^(-0.2) as search_radius
    from
        sd,
        md
)
select
    gid as id,
    g as geom,
    kd :: int as kdensity
from
    sr,
    dist as a,
    lateral(
        select
            count(*) as kd
        from
            dist _b
        where
            st_dwithin(a.g, _b.g, sr.search_radius)
    ) b;

end;

$$ language plpgsql immutable parallel safe;
```

### 10.36

```sql
create table east_village_kde as WITH a AS(
    SELECT
        array_agg(ogc_fid) as ids,
        array_agg(geom) as geoms
    FROM
        nyc_2015_tree_census
    where
        st_intersects(
            geom,
            (
                select
                    geom
                from
                    nyc_neighborhoods
                where
                    neighborhood = 'East Village'
            )
        )
)
SELECT
    b.*
FROM
    a,
    ST_KDensity(a.ids, a.geoms) b
```

## 10.8 Isovist

### 10.37

```sql
with buildings_0 as(
    select
        t.geom
    from

        -- Find all the buildingswithin 2 kilometers of Times Square where
        -- geometries are stored in an array
        unnest(
            (
                select
                    array_agg(geom)
                from
                    nyc_building_footprints
                where
                    st_dwithin(
                        geom :: geography,
                        st_setsrid(st_makepoint(-73.985136, 40.758786), 4326) :: geography,
                        2000
                    )
            )
        ) as t(geom)
),
buildings_crop as(
    
    -- Now only the buildings within 630 meters of Times Square
    select
        geom
    from
        buildings_0
    where
        st_dwithin(
            st_setsrid(st_makepoint(-73.985136, 40.758786), 4326) :: geography,
            geom :: geography,
            630
        )
),
buildings as(

    -- Union these two tables together
    select
        geom
    from
        buildings_crop
    union
    all
    select
        st_buffer(
            st_setsrid(st_makepoint(-73.985136, 40.758786), 4326) :: geography,
            630
        ) :: geometry as geom
)
select
    *
from
    buildings
```

### 10.41

```sql
create
or replace function isovist(

    -- Sets up the arguments for our function
    in center geometry,
    in polygons geometry [],
    in radius numeric default 150,
    in rays integer default 36,
    in heading integer default -999,
    in fov integer default 360
) returns geometry as $$ declare arc numeric;

-- Creates static variables for angle and geometry
angle_0 numeric;

geomout geometry;

-- Calculates the arc distance using the field of view (fov)
-- degrees and the number of rays
begin arc := fov :: numeric / rays :: numeric;

if fov = 360 then angle_0 := 0;

else angle_0 := heading - 0.5 * fov;

end if;

with buildings_0 as(
    select
        t.geom
    from
        unnest(polygons) as t(geom)
),
buildings_crop as(
    select
        geom
    from
        buildings_0
    where
        st_dwithin(center :: geography, geom :: geography, radius)
),
buildings as(
    select
        geom
    from
        buildings_crop
    union
    all
    select
        st_buffer(center :: geography, radius) :: geometry as geom
),
rays as(
    select
        t.n as id,
        st_setsrid(
            st_makeline(
                center,
                st_project(
                    center :: geography,
                    radius + 1,
                    radians(angle_0 + t.n :: numeric * arc)
                ) :: geometry
            ),
            4326
        ) as geom
    from
        generate_series(0, rays) as t(n)
),
intersections as(
    select
        r.id,
        (
            st_dump(st_intersection(st_boundary(b.geom), r.geom))
        ).geom as point
    from
        rays r
        left join buildings b on st_intersects(b.geom, r.geom)
),
intersections_distances as(
    select
        id,
        point as geom,
        row_number() over(
            partition by id
            order by
                center <-> point
        ) as ranking
    from
        intersections
),
intersection_closest as(
    select
        -1 as id,
        case
            when fov = 360 then null :: geometry
            else center
        end as geom
    union
    all (
        select
            id,
            geom
        from
            intersections_distances
        where
            ranking = 1
        order by
            id
    )
    union
    all
    select
        999999 as id,
        case
            when fov = 360 then null :: geometry
            else center
        end as geom
),
isovist_0 as(
    select
        st_makepolygon(st_makeline(geom)) as geom
    from
        intersection_closest
),
isovist_buildings as(
    select
        st_collectionextract(st_union(b.geom), 3) as geom
    from
        isovist_0 i,
        buildings_crop b
    where
        st_intersects(b.geom, i.geom)
)
select
    coalesce(st_difference(i.geom, b.geom), i.geom) into geomout
from
    isovist_0 i,
    isovist_buildings b;

return geomout;

end;

$$ language plpgsql immutable;
```

### 10.42

```sql
select
    *
from
    isovist(

        -- This is our center point in Times Square
        st_setsrid(st_makepoint(-73.985136, 40.758786), 4326),
        (
            -- Selects all the geometries 
            select
                array_agg(geom)
            from
                nyc_building_footprints
            where
                st_dwithin(
                    geom :: geography,
                    st_setsrid(st_makepoint(-73.985136, 40.758786), 4326) :: geography,
                    2000
                )
        ),
        300,
        36
    )
```