# 13 - Routing and networks with pgRouting

## 13.1 Prepare data to use in pgRouting

### 13.1

```sh
docker run --name mini-postgis -p 35432:5432 --network="host" 
-v /Users/mattforrest/Desktop/Desktop/spatial-sql-book/raster:/mnt/mydata 
-e POSTGRES_USER=admin -e POSTGRES_PASSWORD=password -d postgis/postgis:15-master
```

### 13.2

```sh
docker container exec -it mini-postgis bash
```

### 13.3

```sh
apt update
apt install osm2pgrouting
```

### 13.4

```sh
apt install osmctools
```

### 13.5

```sh
osmfilter /mnt/mydata/planet_-74.459,40.488_-73.385,41.055.osm --keep="highway=" \
-o=/mnt/mydata/good_ways.osm
```

## 13.2 Create a simple route in pgRouting

### 13.6

```sh
osm2pgrouting \
    -f "/mnt/mydata/good_ways.osm" \
    -d routing \
    -p 25432 \
    -U docker \
    -W docker \
    --clean
```

### 13.11

```sql
-- Find the source ID closest to the starting point
with start as (
    select
        source
    from
        ways
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('point (-74.244391 40.498995)'),
            4326
        )
    limit
        1
), 

-- Find the source ID closest to the end point
destination as (
    select
        source
    from
        ways
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('point (-73.902630 40.912329)'),
            4326
        )
    limit
        1
)

-- Run our pgRouting query
select
    st_union(the_geom) as route
from
    pgr_dijkstra(
        'select gid as id, source, target, cost,
        reverse_cost, st_length(st_transform(the_geom, 3857)) 
        as cost from ways',
        (
            select
                source
            from
                start
        ),
        (
            select
                source
            from
                destination
        ),
        true
    ) as di
    join ways as pt on di.edge = pt.gid;
```

### 13.12

```sql
select
    tag_id,
    tag_key,
    tag_value
from
    configuration
order by
    tag_id;
```

### 13.13

```sql
create table car_config as
select
    *
from
    configuration
```

### 13.14

```sql
alter table
    car_config
add
    column penalty float;
```

### 13.15

```sql
update car_config set penalty=1
```

### 13.16

```sql
update
    car_config
set
    penalty = -1.0
where
    tag_value in ('steps', 'footway', 'pedestrian');

update
    car_config
set
    penalty = 5
where
    tag_value in ('unclassified');
```

### 13.17

```sql
update
    car_config
set
    penalty = 0.5
where
    tag_value in ('tertiary');

update
    car_config
set
    penalty = 0.3
where
    tag_value in (
        'primary',
        'primary_link',
        'trunk',
        'trunk_link',
        'motorway',
        'motorway_junction',
        'motorway_link',
        'secondary'
    );
```

### 13.19

```sql
with start as (
    select
        source
    from
        ways
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('point (-74.244391 40.498995)'),
            4326
        )
    limit
        1
), destination as (
    select
        source
    from
        ways
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('point (-73.902630 40.912329)'),
            4326
        )
    limit
        1
)
select
    st_union(the_geom) as route
from
    pgr_dijkstra(
        'select
            gid as id,
            source,
            target,
            cost_s * penalty as cost,
            reverse_cost_s * penalty as reverse_cost,
            st_length(st_transform(the_geom, 3857)) as length
        from
            ways
            join car_config using (tag_id)',
        (
            select
                source
            from
                start
        ),
        (
            select
                source
            from
                destination
        ),
        true
    ) as di
    join ways as pt on di.edge = pt.gid;
```

## 13.3 Building an origin-destination matrix

### 13.20

```sh
osmfilter mnt/mydata/planet_-74.459,40.488_-73.385,41.055.osm \
--keep="highway= route= cycleway= bicycle= segregated=" \
-o=mnt/mydata/bike_ways.osm
```

### 13.21

```sh
osm2pgrouting \
-f "mnt/mydata/bike_ways.osm" \
-d bike \
-p 25432 \
-U docker \
-W docker \
--clean
```

### 13.22

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker dbname=bike port=25432" \
nyc_pharmacies.geojson \
-nln nyc_pharmacies -lco GEOMETRY_NAME=geom 

ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker dbname=bike port=25432" \
Building_Footprints.geojson \
-nln nyc_building_footprints -lco GEOMETRY_NAME=geom
```

### 13.23

```sql
alter table
    configuration
add
    column penalty float;

update
    configuration
set
    penalty = 1.0;
```

### 13.24

```sql
update
    configuration
set
    penalty = 10.0
where
    tag_value in ('steps', 'footway', 'pedestrian');

update
    configuration
set
    penalty = 0.3
where
    tag_key in ('cycleway');

update
    configuration
set
    penalty = 0.3
where
    tag_value in ('cycleway', 'bicycle');

update
    configuration
set
    penalty = 0.7
where
    tag_value in ('tertiary', 'residential');

update
    configuration
set
    penalty = 1
where
    tag_value in ('secondary');

update
    configuration
set
    penalty = 1.2
where
    tag_value in ('primary', 'primary_link');

update
    configuration
set
    penalty = 2
where
    tag_value in (
        'trunk',
        'trunk_link',
        'motorway',
        'motorway_junction',
        'motorway_link'
    );
```

### 13.26

```sql
with pharm as (
    select
        name,
        st_centroid(geom) as geom,
        id
    from
        nyc_pharmacies
    where
        st_dwithin(
            st_centroid(geom) :: geography,
            st_setsrid(st_makepoint(-73.9700743, 40.6738928), 4326) :: geography,
            3000
        )
    order by
        random()
    limit
        3
), bldgs as (
    select
        st_centroid(geom) as bldg_geom,
        bin
    from
        nyc_building_footprints
    where
        st_dwithin(
            st_centroid(geom) :: geography,
            st_setsrid(st_makepoint(-73.9700743, 40.6738928), 4326) :: geography,
            3000
        )
    order by
        random()
    limit
        10
), 

c as (

    -- First we select all the columns from the pharm, bldgs, and wid CTEs and subqueries
    select
        pharm.*,
        bldgs.*,
        wid.*
    from

        -- We perform a cross join to find all possible matches between
        -- the 5 pharmacies and the 20 buildings
        pharm,
        bldgs
        cross join lateral (

            -- For each row find the start and end way IDs
            with start as (
                select
                    source
                from
                    ways
                order by
                    the_geom <-> pharm.geom
                limit
                    1
            ), destination as (
                select
                    source
                from
                    ways
                order by
                    ways.the_geom <-> st_centroid(bldgs.bldg_geom)
                limit
                    1
            )
            select
                start.source as start_id,
                destination.source as end_id
            from
                start,
                destination
        ) wid
)
select
    -- For each combination we get the sum of the cost in distance, seconds, and route length
    -- and we repeat this for every row, or possible combinatino
    sum(di.cost) as cost,
    sum(length) as length,
    sum(pt.cost_s) as seconds,
    st_union(st_transform(the_geom, 4326)) as route
from
    pgr_dijkstra(
        'select 
        gid as id, 
        source, 
        target, 
        cost_s * penalty as cost, 
        reverse_cost_s * penalty as reverse_cost, 
        st_length(st_transform(the_geom, 3857)) as length 
        from ways 
        join configuration using (tag_id)',
        array(
            select
                distinct start_id
            from
                c
        ),
        array(
            select
                distinct end_id
            from
                c
        ),
        true
    ) as di
    join ways as pt on di.edge = pt.gid
group by
    start_vid,
    end_vid
```

## 13.4 Traveling salesman problem

### 13.29

```sql
-- Find 10 random Rite-Aid locations
with a as (
    select
        *
    from
        nyc_pharmacies
    where
        name ilike '%rite%'
    limit
        10
)
select

    -- For each pharmacy we will find 10 random 
    -- buildings within 800 meters
    a.name,
    a.id as pharm_id,
    a.geom as pharm_geom,
    b.*
from
    a
    cross join lateral (
        select
            bin as building_id,
            geom
        from
            nyc_building_footprints
        where
            st_dwithin(
                st_centroid(geom) :: geography,
                st_centroid(a.geom) :: geography,
                800
            )
        order by
            random()
        limit
            10
    ) b
```

### 13.30

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker dbname=bike port=25432" \
rite_aid_odm.csv \
-nln rite_aid_odm -lco GEOMETRY_NAME=geom -oo AUTODETECT_TYPE=true
```

### 13.32

```sql
create table rite_aid_tsp as with a as (
    select
        distinct b.pharm_id as id,
        b.geom,
        s.source
    from
        rite_aid_odm b
        cross join lateral(
            SELECT
                source
            FROM
                ways
            ORDER BY
                the_geom <-> b.pharm_geom
            limit
                1
        ) s
), b as (
    select
        b.pharm_id as id,
        s.source
    from
        rite_aid_odm b
        cross join lateral(
            SELECT
                source
            FROM
                ways
            ORDER BY
                the_geom <-> b.geom
            limit
                1
        ) s
), c as (
    select
        a.id,
        a.source,

        -- Constructs an array with the way ID of the pharmacy as the first item
        array_prepend(a.source, array_agg(distinct b.source)) as destinations
    from
        a
        join b using (id)

    -- Will return one row per pharmacy ID
    group by
        a.id,
        a.source
)
select
    *
from
    c
```

### 13.33

```sql
create table rite_aid_tsp_odm as

-- Select all the values from the table created in the last step
select
    a.*,
    r.*
from
    rite_aid_tsp a
    cross join lateral (
        select
            *
        from

            -- This will create the cost matrix for each pharmacy
            pgr_dijkstracostmatrix(
                'select 
                gid as id, 
                source, 
                target, 
                cost_s * penalty as cost, 
                reverse_cost_s * penalty as reverse_cost 
                from ways 
                join configuration 
                using (tag_id)',

                -- We can use the array to calculate the distances 
                -- between all locations in the array
                (
                    select
                        destinations
                    from
                        rite_aid_tsp
                    where
                        id = a.id
                ),
                directed := false
            )
    ) r
```

### 13.37

```sql
create table solved_tsp as
select
    s.id,
    s.source,
    tsp.*,
    lead(tsp.node, 1) over (
        partition by s.source
        order by
            tsp.seq
    ) as next_node
from
    rite_aid_tsp s
    cross join lateral (
        select
            *
        from
            pgr_TSP(
                $$
                select
                    *
                from
                    rite_aid_tsp_odm
                where
                    source = $$ || s.source || $$$$
            )
    ) tsp
```

### 13.38

```sql
create table final_tsp_test as 
with a as (
    select
        s.id,
        s.source,
        s.seq,
        s.node,
        s.next_node,
        di.*,
        ways.the_geom,
        st_length(st_transform(ways.the_geom, 3857)) as length
    from
        solved_tsp s,
        
        -- We cross join this to each row 
        pgr_dijkstra(
            'select 
            gid as id, 
            source, 
            target, 
            cost_s, 
			cost_s * penalty as cost, 
			reverse_cost_s * penalty as reverse_cost 
            from ways 
            join configuration
            using (tag_id)',

            -- We create a route between the current node and the next node
            s.node,
            s.next_node,
            true
        ) as di
        join ways on di.node = ways.source
)
select

    -- Union the geometries and find the sum of the cost and length for each route
    st_union(st_transform(the_geom, 4326)) as route,
    source,
    sum(cost) as cost,
    sum(length) as length
from
    a
group by
    source
```

## 13.5 Creating travel time polygons or isochones

### 13.41

```sql
with start as (
    select
        source
    from
        ways
        join car_config using (tag_id)
    where
        car_config.penalty != -1
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('POINT (-73.987374 40.722349)'),
            4326
        )
    limit
        1
), b as (
    select
        *
    from
        pgr_drivingdistance(
            'select 
            gid as id, 
            source, 
            target,
            cost_s * 2.5 as cost, 
            reverse_cost_s * 2.5 as reverse_cost 
            from ways 
            join car_config 
            using (tag_id) 
            where tag_id in (110, 100, 124, 115, 112, 125, 109, 101, 
            103, 102, 106, 107, 108, 104, 105)',
            (
                select
                    source
                from
                    start
            ),
            600
        )
)

-- Union the geometries into a single geometry
select
	st_union(ways.the_geom)
from
    ways
where
	gid in (select edge from b)
```

### 13.42

```sql
with start as (
    select
        source
    from
        ways
        join car_config using (tag_id)
    where
        car_config.penalty != -1
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('POINT (-73.987374 40.722349)'),
            4326
        )
    limit
        1
), b as (
    select
        *
    from
        pgr_drivingdistance(
            'select 
            gid as id, 
            source, 
            target, 
            cost_s * 2.5 as cost, 
            reverse_cost_s * 2.5 as reverse_cost 
            from ways 
            join car_config 
            using (tag_id) 
            where tag_id in (110, 100, 124, 115, 112, 125, 
            109, 101, 103, 102, 106, 107, 108, 104, 105)',
            (
                select
                    source
                from
                    start
            ),
            600
        )
)
select
    -- Creates a concave hull around the entire routes geometry
    st_concavehull(
        st_transform(
            st_union(the_geom), 4326),
        0.1) as geom
from
    ways
where
    gid in (
        select
            distinct edge
        from
            b
    )
```

```sql

```

### 13.43

```sql
with start as (
    select
        source
    from
        ways
        join car_config using (tag_id)
    where
        car_config.penalty != -1
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('POINT (-73.987374 40.722349)'),
            4326
        )
    limit
        1
), b as (
    select
        *
    from
        pgr_drivingdistance(
            'select gid as id, 
            source, 
            target, 
            cost_s * 2.5 as cost, 
            reverse_cost_s * 2.5 as reverse_cost 
            from ways 
            join car_config 
            using (tag_id) 
            where tag_id in (110, 100, 124, 115, 112, 
            125, 109, 101, 103, 102, 106, 107, 108, 104, 105)',
            (
                select
                    source
                from
                    start
            ),
            600
        )
)
select

    -- Turn it all into a polygon
    st_makepolygon(

        -- Find the exterior ring which will eliminate islands
        st_exteriorring(

            -- Create a 20 meter buffer
            st_buffer(
                st_transform(
                    st_union(the_geom), 4326) :: geography,
                20
            ) :: geometry
        )
    ) as geom
from
    ways
where
    gid in (
        select
            distinct edge
        from
            b
    )
```

### 13.44

```sql
with start as (
    select
        source
    from
        ways
        join configuration using (tag_id)
    where
        configuration.penalty <= 1
    order by
        the_geom <-> st_setsrid(
            st_geomfromtext('POINT (-73.987374 40.722349)'),
            4326
        )
    limit
        1
), b as (
    select
        *
    from
        pgr_drivingdistance(
            'select 
            gid as id, 
            source, 
            target, 
            cost_s * 2.5 as cost, 
            reverse_cost_s * 2.5 as reverse_cost 
            from ways 
            join configuration 
            using (tag_id) 
            where penalty <= 1',
            (
                select
                    source
                from
                    start
            ),
            600
        )
)
select
    st_makepolygon(
        st_exteriorring(
            st_buffer(
                st_transform(st_union(the_geom), 4326) :: geography,
                20
            ) :: geometry
        )
    ) as geom
from
    ways
where
    gid in (
        select
            distinct edge
        from
            b
    )
```
