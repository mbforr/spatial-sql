# 9 - Spatial Analysis

## 9.1 Analyses we have already seen

### 9.1

```sql
select
    spc_common,
    case
        when spc_common ilike '%oak%' then 'Oak'
        when spc_common ilike '%maple%' then 'Maple'
        when spc_common ilike '%pine%' then 'Pine'
        else NULL
    end as tree_type
from
    nyc_2015_tree_census
limit
    100
```

### 9.2

```sql
create temporary table stadiums_matrix as with stadiums as (
    select
        'Citi Field' as stadium,
        buildpoint(-73.845833, 40.756944, 4326) as geom
    union
    select
        'Yankees Stadium' as stadium,
) buildpoint(-73.926389, 40.829167, 4326) as geom
select
    a.stadium,
    b.neighborhood,
    st_distance(st_centroid(b.geom), a.geom)
from
    stadiums a,
    nyc_neighborhoods b
```

### 9.3

```sql
-- Find all the rows from the stadiums matrix for Citi Field
with mets as (
    select
        *
    from
        stadiums_matrix
    where
        stadium = 'Citi Field'
),

-- Find all the rows from the stadiums matrix for Yankees Stadium
yankees as (
    select
        *
    from
        stadiums_matrix
    where
        stadium = 'Yankees Stadium'
)

select
    a.neighborhood,
    b.st_distance as mets,
    c.st_distance as yankees
from
    nyc_neighborhoods a
    join mets b using (neighborhood)
    join yankees c using (neighborhood)
```

### 9.4

```sql
with mets as (
    select
        *
    from
        stadiums_matrix
    where
        stadium = 'Citi Field'
),
yankees as (
    select
        *
    from
        stadiums_matrix
    where
        stadium = 'Yankees Stadium'
)
select
    a.neighborhood,
    a.geom,
    b.st_distance as mets,
    c.st_distance as yankees
from
    nyc_neighborhoods a
    join mets b using (neighborhood)
    join yankees c using (ntaname)
where
    c.st_distance < b.st_distance
```

### 9.5

```sql
with mets as (
    select
        *
    from
        stadiums_matrix
    where
        stadium = 'Citi Field'
),
yankees as (
    select
        *
    from
        stadiums_matrix
    where
        stadium = 'Yankees Stadium'
)
select
    a.ntaname,
    a.geom,
    b.st_distance as mets,
    c.st_distance as yankees
from
    nyc_neighborhoods a
    join mets b using (neighborhood)
    join yankees c using (neighborhood)
where
    b.st_distance < c.st_distance
```

### 9.6

```sql
select
    st_makeenvelope(-74.047196, 40.679654, -73.906769, 40.882012, 4326)
```

### 9.7

```sql
select
    st_envelope(st_transform(geom, 4326)) as geom
from
    nyc_zips
where
    zipcode = '11231'
```

### 9.8

```sql
select
    st_collect(st_transform(geom, 4326)) as geom
from
    nyc_zips
where
    zipcode = '11231'
```

### 9.9

```sql
select
    *
from
    nyc_bike_routes
order by
    st_length(geom) desc
limit
    1
```

### 9.10

```sql
select
    st_lineinterpolatepoint(st_linemerge(geom), 0.5) as geom
from
    nyc_bike_routes
where
    ogc_fid = 20667
```

### 9.11

```sql
select
    st_length(st_transform(geom, 3857))
from
    nyc_bike_routes
where
    ogc_fid = 20667
```

### 9.12

```sql
select
    st_lineinterpolatepoint(
        -- This is the line created from ST_LineMerge
        st_linemerge(geom),

        -- Here we divide 500 by the total length of the route
        (
            500 / (
                select
                    st_length(st_transform(geom, 3857))
                from
                    nyc_bike_routes
                where
                    ogc_fid = 20667
            )
        )
    ) as geom
from
    nyc_bike_routes
where
    ogc_fid = 20667
```

### 9.13

```sql
select
    st_lineinterpolatepoints(

        -- Our merged geometry
        st_linemerge(geom),

        -- Dividing the length of the route by 75
        (
            75 / (
                select
                    st_length(st_transform(geom, 3857))
                from
                    nyc_bike_routes
                where
                    ogc_fid = 20667
            )
        )
    ) as geom
from
    nyc_bike_routes
where
    ogc_fid = 20667
```

### 9.14

```sql
select
    st_intersection(
        st_transform(geom, 4326),
        st_makeenvelope(-73.981667, 40.76461, -73.949314, 40.800368, 4326)
    ) as geom
from
    nyc_zips
```

### 9.15

```sql
select
    st_difference(
        st_transform(geom, 4326),
        st_makeenvelope(-73.981667, 40.76461, -73.949314, 40.800368, 4326)
    ) as geom
from
    nyc_zips
```

## 9.2 New analyses

### 9.16

```sql
select
    st_generatepoints(st_transform(geom, 4326), 50) as geom
from
    nyc_zips
where
    zipcode = '10001'
```

### 9.17

```sql
select
    (
        st_dump(
            st_generatepoints(st_transform(geom, 4326), 5000)
        )
    ).geom as geom
from
    nyc_zips
where
    zipcode = '10001'
```

### 9.18

```sql
select
    st_transform(geom, 4326) as geom
from
    nyc_zips
where
    zipcode = '11101'
```

### 9.19

```sql
select
    (
        st_dump(
            st_generatepoints(st_transform(geom, 4326), 5000)
        )
    ).geom as geom
from
    nyc_zips
where
    zipcode = '11101'
```

### 9.20

```sql
-- The "points" CTE generates 5,000 random points in the 11101 postal code
with points as (
    select
        (
            st_dump(
                st_generatepoints(st_transform(geom, 4326), 5000)
            )
        ).geom as geom
    from
        nyc_zips
    where
        zipcode = '11101'
),

-- Create 6 even clusters using ST_ClusterKMeans
cluster as (
    select
        geom,
        st_clusterkmeans(geom, 6) over () AS cluster
    from
        points
)

-- Group or collect each cluster and find the centroid
select
    st_centroid(
        st_collect(geom)
    ) as geom,
    cluster
from
    cluster
group by
    cluster
```

### 9.21

```sql
with points as (
    select
        (
            st_dump(
                st_generatepoints(st_transform(geom, 4326), 5000)
            )
        ).geom as geom
    from
        nyc_zips
    where
        zipcode = '11101'
),
cluster as (
    select
        geom,
        st_clusterkmeans(geom, 6) over () AS cluster
    from
        points
),
centroid as (
    select
        st_centroid(st_collect(geom)) as geom,
        cluster
    from
        cluster
    group by
        cluster
)

-- In this step we collect the centroids
-- then create Voronoi polygons, then extract
-- each individual polygon
select
    (
        st_dump(st_voronoipolygons(st_collect(geom)))
    ).geom AS geom
from
    centroid
```

### 9.22

```sql
with points as (
    select
        (
            st_dump(
                st_generatepoints(st_transform(geom, 4326), 5000)
            )
        ).geom as geom
    from
        nyc_zips
    where
        zipcode = '11101'
),
cluster as (
    select
        geom,
        st_clusterkmeans(geom, 6) over () AS cluster
    from
        points
),
centroid as (
    select
        st_centroid(st_collect(geom)) as geom,
        cluster
    from
        cluster
    group by
        cluster
),
voronoi as (
    select
        (
            st_dump(st_voronoipolygons(st_collect(geom)))
        ).geom AS geom
    from
        centroid
)

-- In the last step, we find the intersection (or clip)
-- the 11101 zip code and the Voronoi polygons
select
    st_intersection(
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '11101'
        ),
        geom
    )
from
    voronoi
```

### 9.23

```sql
-- Setting up our function and inputs
create
or replace function st_equalarea(
    seed_points int,
    tablename text,
    polygons int,
    unique_id text
) 

-- Define that the function returns a table and the return values

returns table (id varchar, geom geometry) language plpgsql 
as $$ 
begin 
return query 

-- This will run the string as a query, filling in the values
execute format(
    'with points as (select %s as id, 
    (st_dump( st_generatepoints( geom , %s) )).geom as geom from %s), 
    cluster as (select geom, id, st_clusterkmeans(geom, %s) 
    over (partition by id) AS cluster from points), 
    centroid as (select id, st_centroid(st_collect(geom)) as geom, 
    cluster from cluster group by cluster, id), 
    voronoi as (select id, (st_dump( st_voronoipolygons( st_collect(geom) ) )).geom 
    AS voronoi_geom from centroid group by id) 
    select b.id, st_intersection(a.geom, b.voronoi_geom) as 
    geom from voronoi b join %s a on b.id = %s;',

    -- These values will replace each instance of %s in the order they appear
    unique_id,
    seed_points,
    tablename,
    polygons,
    tablename,
    unique_id
);

end;
$$
```

### 9.24

```sql
select
    *
from
    st_equalarea(1000, 'nyc_zips', 6, 'zipcode')
```

### 9.25

```sql
select
    id,
    st_transform(geom, 4326) as geom
from
    st_equalarea(1000, 'nyc_zips', 6, 'zipcode')
```

### 9.26

```sql
create
or replace function st_equalareawithinput(
    seed_points int,
    tablename text,
    polygons int,
    unique_id text
) returns table (id varchar, geom geometry) language plpgsql as $$ begin return query execute format(
    'with points as (select %s as id, (st_dump( st_generatepoints( geom , %s) )).geom 
    as geom from %s), 
    area as (select st_area(geom) as area, zipcode from %s), 
    cluster as (select points.geom, points.id, 
    st_clusterkmeans(points.geom, ceil((a.area/(%s)))::int) over (partition by id) AS cluster 
    from points left join area a on a.zipcode = points.id), 
    centroid as (select id, st_centroid(st_collect(geom)) as geom, 
    cluster from cluster group by cluster, id), 
    voronoi as (select id,(st_dump( st_voronoipolygons( st_collect(geom) ) )).geom AS voronoi_geom 
    from centroid group by id) select b.id, st_intersection(a.geom, b.voronoi_geom) as geom 
    from voronoi b join %s a on b.id = %s;',
    unique_id,
    seed_points,
    tablename,
    tablename,
    polygons,
    tablename,
    unique_id
);

end;

$$
```

### 9.29

```sql
create table nyc_zips_50_acres as
select
    id,
    st_transform(geom, 4326) as geom
from
    st_equalareawithinput(1000, 'nyc_zips', (43560 * 50), 'zipcode')
```

### 9.30

```sql
-- Create a point at the Plaza Hotel
with point as (
    select
        buildpoint(-73.9730423, 40.7642784, 4326) as geom
),

-- Find all the pickups within 50 meters of the Plaza
-- on June 1st, 2016 and calculate distance with a cross
-- join. Since it is just one point the cross join is acceptable
-- since it is just one row in that table.
start as (
    select
        *
    from
        nyc_yellow_taxi_0601_0615_2016,
        point
    where
        st_dwithin(pickup :: geography, point.geom :: geography, 50)
        and pickup_datetime :: date = '06-01-2016'
)
select
    ogc_fid,
    trip_distance,
    total_amount,
    
    -- Create a line from the Plaza (in the subquery in the second argument)
    -- and all the dropoff locations
    st_makeline(
        dropoff,
        (
            select
                geom
            from
                point
        )
    ) as geom
from
    start
```

### 9.31

```sql
select
    a.id,
    st_makeline(a.geom, b.geom) as geom
from
    destinations a
    left join origins b using (id)
```

### 9.32

```sql
select
    geom,
    health,
    spc_common
from
    nyc_2015_tree_census
order by
    st_distance(buildpoint(-73.977733, 40.752273, 4326), geom)
limit
    3
```

### 9.33

```sql
select
    geom,
    health,
    spc_common
from
    nyc_2015_tree_census
order by
    buildpoint(-73.977733, 40.752273, 4326) <-> geom
limit
    3
```

### 9.34

```sql
-- Create a point at John's of Bleeker Street
with point as (
    select
        buildpoint(-74.003544, 40.7316243, 4326) :: geography as geog
),

-- Find all the buildings that are within 1 kilometer of John's
buildings as (
    select
        geom,
        name,
        mpluto_bbl
    from
        nyc_building_footprints
    where
        st_dwithin(
            geom::geography,
            (
                select
                    geog
                from
                    point
            ),
            1000
        )
)

-- Selects three columns from the "buildings" CTE
-- And one from the cross join lateral
select
    geom,
    name,
    mpluto_bbl,
    nearest.distance
from
    buildings

    -- This join selects the distance to the nearest fire hydrant laterally
    -- or for each row in the "buildings" dataset. As you can see it uses
    -- columns from the outside query, and limits the results to 1
    cross join lateral (
        select
            unitid,
            st_distance(geom :: geography, buildings.geom :: geography) as distance
        from
            nyc_fire_hydrants
        order by
            geom <-> buildings.geom
        limit
            1
    ) nearest
```

### 9.35

```sql
create table nearest_hydrant_pizza as with point as (
	select
		buildpoint(-74.003544, 40.7316243, 4326) :: geography as geog
),
buildings as (
	select
		geom,
		name,
		mpluto_bbl
	from
		nyc_building_footprints
	where
		st_dwithin(
			geom :: geography,
			(
				select
					geog
				from
					point
			),
			1000
		)
)
select
	geom,
	name,
	mpluto_bbl,
	nearest.distance
from
	buildings
	cross join lateral (
		select
			unitid,
			st_distance(geom :: geography, buildings.geom :: geography) as distance
		from
			nyc_fire_hydrants
		order by
			geom <-> buildings.geom
		limit
			1
	) nearest
```

### Import road centerlines

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \ dbname=gis port=25432" \
street_centerlines.geojson \
-nln nyc_street_centerlines -lco GEOMETRY_NAME=geom
```

### 9.36

```sql
select
    *
from
    nyc_yellow_taxi_0601_0615_2016
where
    st_dwithin(
        pickup :: geography,
        buildpoint(-73.987224, 40.733342, 4326) :: geography,
        300
    )
    and pickup_datetime between '2016-06-02 9:00:00+00'
    and '2016-06-02 18:00:00+00'
```

### 9.37

```sql
-- Select all pickups within 300 meters of Union Square
-- between 9am and 6pm on June 2nd, 2016
with pickups as (
    select
        pickup,
        tip_amount,
        total_amount
    from
        nyc_yellow_taxi_0601_0615_2016
    where
        st_dwithin(
            pickup :: geography,
            buildpoint(-73.987224, 40.733342, 4326) :: geography,
            300
        )
        and pickup_datetime between '2016-06-02 9:00:00+00'
        and '2016-06-02 18:00:00+00'
)

-- Find the nearest road to each point using a 
-- cross join lateral
select
    a.*,
    street.name,
    street.ogc_fid,
    street.geom
from
    pickups a
    cross join lateral (
        select
            ogc_fid,
            full_stree as name,
            geom
        from
            nyc_street_centerlines
        order by
            a.pickup <-> geom
        limit
            1
    ) street
```

### 9.38

```sql
with pickups as (
    select
        pickup,
        tip_amount,
        total_amount
    from
        nyc_yellow_taxi_0601_0615_2016
    where
        st_dwithin(
            pickup :: geography,
            buildpoint(-73.987224, 40.733342, 4326) :: geography,
            300
        )
        and pickup_datetime between '2016-06-02 9:00:00+00'
        and '2016-06-02 18:00:00+00'
),
nearest as (
    select
        a.*,
        street.name,
        street.ogc_fid,
        street.geom
    from
        pickups a
        cross join lateral (
            select
                ogc_fid,
                full_stree as name,
                geom
            from
                nyc_street_centerlines
            order by
                a.pickup <-> geom
            limit
                1
        ) street
)
select
    a.*,

    -- Create a line between the original point and the new snapped point
    st_makeline(
        pickup,
        st_lineinterpolatepoint(
            st_linemerge(b.geom),
            st_linelocatepoint(st_linemerge(b.geom), pickup)
        )
    ) as line,

    -- Add a column for the snapped point
    st_lineinterpolatepoint(
        st_linemerge(b.geom),
        st_linelocatepoint(st_linemerge(b.geom), pickup)
    ) as snapped
from
    nearest a
    join nyc_street_centerlines b using (ogc_fid)
```

### 9.39

```sql
create
or replace view nyc_taxi_union_square as with pickups as (
    select
        pickup,
        tip_amount,
        total_amount
    from
        nyc_yellow_taxi_0601_0615_2016
    where
        st_dwithin(
            pickup :: geography,
            buildpoint(-73.987224, 40.733342, 4326) :: geography,
            300
        )
        and pickup_datetime between '2016-06-02 9:00:00+00'
        and '2016-06-02 18:00:00+00'
),
nearest as (
    select
        a.*,
        street.name,
        street.ogc_fid,
        street.geom
    from
        pickups a
        cross join lateral (
            select
                ogc_fid,
                full_stree as name,
                geom
            from
                nyc_street_centerlines
            order by
                a.pickup <-> geom
            limit
                1
        ) street
)
select
    a.*,
    st_makeline(
        pickup,
        st_lineinterpolatepoint(
            st_linemerge(b.geom),
            st_linelocatepoint(st_linemerge(b.geom), pickup)
        )
    ) as line,
    st_lineinterpolatepoint(
        st_linemerge(b.geom),
        st_linelocatepoint(st_linemerge(b.geom), pickup)
    ) as snapped
from
    nearest a
    join nyc_street_centerlines b using (ogc_fid)
```

### 9.40

```sql
create table nyc_taxi_union_square_snapped as
select
    snapped,
    name,
    ogc_fid
from
    nyc_taxi_union_square;
    
create table nyc_taxi_union_square_roads as
select
    geom,
    name,
    ogc_fid
from
    nyc_taxi_union_square; 
    
create table nyc_taxi_union_square_points as
select
    pickup,
    name,
    ogc_fid
from
    nyc_taxi_union_square; 
    
create table nyc_taxi_union_square_lines as
select
    lines,
    name,
    ogc_fid
from
    nyc_taxi_union_square;
```

### 9.41

```sql
-- Calculate the tip percentage for each trip with a total over $0
with a as (
    select
        *,
        tip_amount /(total_amount - tip_amount) as tip_percent
    from
        nyc_taxi_union_square
    where
        total_amount > 0
)


-- Get the average tip percentage for each road segment
select
    avg(a.tip_percent),
    b.geom,
    b.ogc_fid
from
    a
    join nyc_street_centerlines b using (ogc_fid)
group by
    b.geom,
    b.ogc_fid
```

### 9.42

```sql
create table nyc_taxi_union_square_tips as with a as (
    select
        *,
        tip_amount / total_amount as tip_percent
    from
        nyc_taxi_union_square
    where
        total_amount > 0
)
select
    avg(a.tip_percent),
    b.geom,
    b.ogc_fid
from
    a
    join nyc_street_centerlines b using (ogc_fid)
group by
    b.geom,
    b.ogc_fid
```

### 9.43

```sql
select
    mode() within group (
        ORDER BY
            a.spc_common
    ) as most_common
from
    nyc_2015_tree_census a
    join nyc_neighborhoods b on st_intersects(a.geom, b.geom)
where
    b.neighborhood = 'East Village'
```

### 9.44

```sql
select
    count(a.*),
    a.spc_common
from
    nyc_2015_tree_census a
    join nyc_neighborhoods b on st_intersects(a.geom, b.geom)
where
    b.neighborhood = 'East Village'
group by
    a.spc_common
order by
    count(a.*) desc
```

### 9.45

```sql
with building as (
    select
        geom
    from
        nyc_building_footprints
    where
        name = 'Empire State Building'
)
select
    st_shortestline(h.geom, b.geom)
from
    nyc_fire_hydrants h,
    building b
order by
    h.geom <-> b.geom asc
limit
    100
```

### 9.46

```sql
select
    array(
        select
            geom
        from
            nyc_311
        where
            geom is not null
        limit
            10
    )
```

### 9.47

```sql
select
    st_makeline(
        array(
            select
                geom
            from
                nyc_311
            where
                geom is not null
            order by
                id
            limit
                10
        )
    )
```

### 9.48

```sql
select

    -- Clips the 100 meter buffer out of the 10001 zip code
    st_difference(
        st_transform(geom, 4326),

        -- Creates a 100 meter buffer
        st_buffer(
            buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
            100
        ) :: geometry
    )
from
    nyc_zips
where
    zipcode = '10001'
```

### 9.49

```sql
with a as (
    select
        10001 as id,
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    id,

    -- Takes only the exterior perimiter of the polygon
    st_exteriorring(geom) as geom
from
    a
```

### 9.50

```sql
with a as (
    select
        10001 as id,
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    id,

    -- Creates a new polygon just from the exterior ring
    -- which removes all holes
    st_makepolygon(
        st_exteriorring(geom)
    ) as geom
from
    a
```

### 9.51

```sql
-- Creates a polygon with a hole in zip code 10001
with a as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10001'
),

-- Creates a polygon with a hole in zip code 10017
b as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9773136, 40.7526559, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10017'
),

-- Unions both polygons into a multi-polygon
c as (
    select
        1 as id,
        st_union(a.geom, b.geom)
    from
        a,
        b
)
select
    *
from
    c
```

### 9.52

```sql
with a as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10001'
),
b as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9773136, 40.7526559, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10017'
),
c as (
    select
        1 as id,
        st_union(a.geom, b.geom) as geom
    from
        a,
        b
)
select
    id,
    (st_dump(geom)).geom
from
    c
```

### 9.53

```sql
with a as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10001'
),
b as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9773136, 40.7526559, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10017'
),
c as (
    select
        1 as id,
        st_union(a.geom, b.geom) as geom
    from
        a,
        b
)
select
    id,

    -- Takes the exterior ring from the geometry dump
    st_exteriorring(
        (st_dump(geom)).geom
    )
from
    c
```

### 9.54

```sql
with a as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9936596, 40.7505483, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10001'
),
b as (
    select
        st_difference(
            st_transform(geom, 4326),
            st_buffer(
                buildpoint(-73.9773136, 40.7526559, 4326) :: geography,
                100
            ) :: geometry
        ) as geom
    from
        nyc_zips
    where
        zipcode = '10017'
),
c as (
    select
        1 as id,
        st_union(a.geom, b.geom) as geom
    from
        a,
        b
)
select
    id,

    -- Collect the individual geometries to turn them back into 
    -- one polygon
    st_collect(st_makepolygon(geom)) as geom
from
    (
        select
            id,
            st_exteriorring((st_dump(geom)).geom) as geom
        from
            c
    ) s
group by
    id;
```

### 9.55

```sql
select
    *
from
    st_maximuminscribedcircle(
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '10001'
        )
    )
```

### 9.56

```sql
select
    center
from
    st_maximuminscribedcircle(
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '10001'
        )
    )
```

### 9.57

```sql
select
    st_buffer(center, radius)
from
    st_maximuminscribedcircle(
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '10001'
        )
    )
```

### 9.58

```sql
select
    st_transform(center, 4326) as geom
from
    st_maximuminscribedcircle(
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '10001'
        )
    )
union
select
    st_centroid(st_transform(geom, 4326)) as geom
from
    nyc_zips
where
    zipcode = '10001'
```

## 9.3 Lines to polygons, and polygons to lines

### 9.59

```sql
select
    st_boundary(st_transform(geom, 4326))
from
    nyc_zips
where
    zipcode = '10001'
```

### 9.60

```sql
select
    st_makeline(
        st_pointn(
            st_boundary(st_transform(z.geom, 4326)),
            numbers.num
        ),
        st_pointn(
            st_boundary(st_transform(z.geom, 4326)),
            numbers.num + 1
        )
    ),
    numbers.num
from
    nyc_zips z
    cross join lateral generate_series(1, st_npoints(z.geom) - 1) as numbers(num)
where
    z.zipcode = '10001'
```

### 9.61

```sql
select
    st_polygonize(
        st_makeline(
            st_pointn(
                st_boundary(st_transform(z.geom, 4326)),
                numbers.num
            ),
            st_pointn(
                st_boundary(st_transform(z.geom, 4326)),
                numbers.num + 1
            )
        )
    )
from
    nyc_zips z
    cross join lateral generate_series(1, st_npoints(z.geom) - 1) as numbers(num)
where
    z.zipcode = '10001'
```

## 9.4 Snap points to grid

### 9.62

```sql
select
    st_transform(
        st_snaptogrid(st_transform(geom, 3857), 500, 1000),
        4326
    ) as geom
from
    nyc_311
limit
    100000
```

## 9.5 Tessellate triangles

### 9.63

```sql
select
    st_delaunaytriangles(st_transform(geom, 4326))
from
    nyc_zips
where
    zipcode = '10009'
```

### 9.64

```sql
with a as (
    select
        (
            -- Create a dump to return the individual triangles
            st_dump(

                -- Create the triangles like above
                st_delaunaytriangles(st_transform(geom, 4326))
            )
        ).geom
    from
        nyc_zips
    where
        zipcode = '10009'
)

-- Select and order by areas 
select
    a.geom,
    st_area(geom) as area
from
    a
order by
    st_area(geom) desc
limit
    10
```

## 9.6 Tapered buffers

### 9.65

```sql
-- Select all bike routes on Hudson Street
with lines as (
    select
        1 as id,
        st_linemerge(st_union(geom)) as geom
    from
        nyc_bike_routes
    where
        street = 'HUDSON ST'
)
select
    *
from
    lines
```

### 9.66

```sql
with lines as (
    select
        1 as id,
        ST_LineMerge(st_union(geom)) as geom
    from
        nyc_bike_routes
    where
        street = 'HUDSON ST'
),

-- Dump all of the points and find the length of the geometry
first as (
    select
        id,
        st_dumppoints(geom) as dump,
        st_length(geom) as len,
        geom
    from
        lines
)
select
    *
from
    first
```

### 9.67

```sql
with lines as (
    select
        1 as id,
        ST_LineMerge(st_union(geom)) as geom
    from
        nyc_bike_routes
    where
        street = 'HUDSON ST'
),
first as (
    select
        id,
        st_dumppoints(geom) as dump,
        st_length(geom) as len,
        geom
    from
        lines
),

-- For each path, select the id, path, and a buffer
-- around the path point. Using ST_LineLocatePoint
-- we use the line geometry and the point to find 
-- the distance along the line, then make it smaller
-- using the log of the length 
second as (
    select
        id,
        (dump).path [1],
        st_buffer(
            (dump).geom,
            ST_LineLocatePoint(geom, (dump).geom) * log(len)
        ) as geom
    from
        first
)
select
    *
from
    second
```

### 9.68

```sql
with lines as (
    select
        1 as id,
        st_linemerge(st_union(geom)) as geom
    from
        nyc_bike_routes
    where
        street = 'HUDSON ST'
),
first as (
    select
        id,
        st_dumppoints(geom) as dump,
        st_length(geom) as len,
        geom
    from
        lines
),
second as (
    select
        id,
        (dump).path [1],
        st_buffer(
            (dump).geom,
            ST_LineLocatePoint(geom, (dump).geom) * len / 10
        ) as geom
    from
        first
),

-- Create a convex hull around the buffers by union-ing
-- all the buffers together. These are ordered using the 
-- LEAD window function and partition
third as (
    select
        id,
        st_convexhull(
            st_union(
                geom,
                lead(geom) over(
                    partition by id
                    order by
                        id,
                        path
                )
            )
        ) as geom
    from
        second
)
select
    id,
    st_union(geom) as geom
from
    third
group by
    id
```

### 9.69

```sql
with lines as (
    select
        1 as id,
        st_linemerge(st_union(geom)) as geom
    from
        nyc_bike_routes
    where
        street = 'HUDSON ST'
),
first as (
    select
        id,
        st_dumppoints(geom) as dump,
        st_length(geom) as len,
        geom
    from
        lines
),
second as (
    select
        id,
        (dump).path [1],
        st_transform(
            st_buffer(st_transform((dump).geom, 3857), random() * 100),
            4326
        ) as geom
    from
        first
),
third as (
    select
        id,
        st_convexhull(
            st_union(
                geom,
                lead(geom) over(
                    partition by id
                    order by
                        id,
                        path
                )
            )
        ) as geom
    from
        second
)
select
    id,
    st_union(geom) as geom
from
    third
group by
    id
```

### 9.70

```sql
select
    st_symdifference(
        (
            select
                geom
            from
                nyc_neighborhoods
            where
                neighborhood = 'NoHo'
        ),
        (
            select
                st_transform(geom, 4326)
            from
                nyc_zips
            where
                zipcode = '10012'
        )
    )
```