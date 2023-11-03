# 7 - Using the GEOMETRY

## 7.2 GEOMETRY Types

### 7.2

```sql
select
   geom
from
   nyc_building_footprints
limit
   1
```

### 7.3

```sql
select
   st_astext(geom) as wkt
from
   nyc_building_footprints
limit
   5
```

### 7.4

```sql
insert into
    geometries
values
    ('point', st_geomfromtext('POINT(0 0)')),
    (
        'line',
        st_geomfromtext('LINESTRING(0 0,1 1,1 2)')
    ),
    (
        'polygon',
        st_geomfromtext(
            'POLYGON((0 0,4 0,4 4,0 4,0 0),(1 1, 2 1, 2 2, 1 2,1 1))'
        )
    )
```

### 7.5

```sql
insert into
    geometries
values
    (
        'multipoint',
        st_geomfromtext('MULTIPOINT((0 0),(1 2))')
    ),
    (
        'multiline',
        st_geomfromtext('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))')
    ),
    (
        'multipolygon',
        st_geomfromtext(
            'MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))'
        )
    ),
    (
        'geometry collection',
        st_geomfromtext(
            'GEOMETRYCOLLECTION(POINT(2 3),LINESTRING(2 3,3 4))'
        )
    )
```

### 7.6

```sql
select
    st_curvetoline(
        st_geomfromtext('CIRCULARSTRING(0 0, 4 0, 4 4, 0 4, 0 0)')
    ) as geom
```

## 7.3 Size of GEOMETRY data

### 7.7

```sql
select
    st_memsize(st_geomfromtext('POINT(0 0)')) as geom
```

### 7.8

```sql
select
    st_memsize(st_geomfromtext('LINESTRING(0 0, 0 1)')) as geom
```

### 7.9

```sql
select
    st_memsize(
        st_geomfromtext('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))')
    ) as geom
```

### 7.10

```sql
select
    st_memsize(geom)
from
    nyc_neighborhoods
where
    neighborhood = 'College Point'
```

### 7.11

```sql
select
    st_npoints(geom) as points,
    st_geometrytype(geom) as type,
    st_numgeometries(geom) as geometries
from
    nyc_neighborhoods
where
    neighborhood = 'College Point'
```

### 7.12

```sql
select
    st_memsize(
        st_geomfromtext('MULTIPOLYGON(((0 0, 1 0, 1 1, 0 1, 0 0)))')
    ) as geom
```

### 7.13

```sql
select
    st_memsize(
        st_geomfromtext(
            'MULTIPOLYGON(((0 0, 1 0, 1 1, 0 1, 0 0)), ((1 1, 2 1, 2 2, 1 2, 1 1)))'
        )
    ) as geom
```

## 7.4 A note on PostGIS documentation

### 7.14

```sql
select
    st_length(
        st_geomfromtext(
            'LINESTRING(743238 2967416,743238 2967450,743265 2967450, 
            743265.625 2967416,743238 2967416)',
            2249
        )
    );

-- Transforming WGS 84 LINESTRING to Massachusetts State Plane Meters
```

### 7.15

```sql
select
    st_length(
        st_transform(
            st_geomfromewkt(
                'srid=4326;linestring(-72.1260 42.45, -72.1240 42.45666, -72.123 42.1546)'
            ),
            26986
        )
    );
```

## 7.6 Constructors

### 7.16

```sql
with a as (
    select
        geom
    from
        nyc_zips
    limit
        5
)
select
    st_collect(geom)
from
    a
```

### 7.17

```sql
with a as (
    select
        geom,
        population,
        zipcode
    from
        nyc_zips
    limit
        5
)
select
    string_agg(zipcode, ',') as zips,
    sum(population) as total_pop,
    st_collect(geom)
from
    a
```

### 7.18

```sql
select
    st_makeenvelope(-66.125091, 18.296531, -65.99142, 18.471986) as geom
```

### 7.19

```sql
select
    st_makeenvelope(
        -66.125091,
        18.296531,
        -65.99142,
        18.471986,
        4326
    ) as geom
```

### 7.20

```sql
select
    st_makepoint(pickup_longitude, pickup_latitude) as geom
from
    nyc_yellow_taxi_0601_0615_2016
limit
    100
```

### 7.21

```sql
select
    ogc_fid,
    st_setsrid(
        st_makepoint(pickup_longitude, pickup_latitude),
        4326
    ) as geom
from
    nyc_yellow_taxi_0601_0615_2016
limit
    100
```

### 7.22

```sql
create or replace function BuildPoint(x numeric, y numeric, srid int) 
    returns geometry 
    language plpgsql 
    as $$ 
        begin 
        return st_setsrid(st_makepoint(x, y), srid);
    end;
$$;
```

### 7.23

```sql
select
    ogc_fid,
    buildpoint(
        pickup_longitude :: numeric,
        pickup_latitude :: numeric,
        4326
    ) as geom
from
    nyc_yellow_taxi_0601_0615_2016
limit
    100
```

### 7.24

```sql
SELECT
    st_setsrid(
        ST_Translate(ST_Scale(ST_Letters('Spatial SQL'), 1, 1), 0, 0),
        4326
    );
```

## 7.7 Accessors

### 7.25

```sql
select
    st_dump(geom) as geom
from
    nyc_neighborhoods
where
    neighborhood = 'City Island'
```

### 7.26

```sql
select
    (st_dump(geom)).geom as geom
from
    nyc_neighborhoods
where
    neighborhood = 'City Island'
```

### 7.27

```sql
select
    st_geometrytype(geom)
from
    nyc_neighborhoods
where
    neighborhood = 'City Island'
```

### 7.28

```sql
select
    st_memsize(geom)
from
    nyc_neighborhoods
where
    neighborhood = 'City Island'
```

### 7.29

```sql
select
    st_npoints(geom)
from
    nyc_neighborhoods
where
    neighborhood = 'City Island'
```

### 7.30

```sql
select
    st_pointn(geom, 1) as geom
from
    nyc_bike_routes
where
    segmentid = '331385'
```

### 7.31

```sql
select
    st_geometrytype(geom) as geom
from
    nyc_bike_routes
where
    segmentid = '331385'
```

### 7.32

```sql
select
    st_pointn(st_linemerge(geom), 1) as geom
from
    nyc_bike_routes
where
    segmentid = '331385'
```

## 7.9 Validators

### 7.33

```sql
select
    *
from
    nyc_building_footprints
where
    st_isvalid(geom) is false
```

### 7.34

```sql
select
    mpluto_bbl,
    st_isvaliddetail(geom)
from
    nyc_building_footprints
where
    mpluto_bbl in ('1022430261', '1016710039', '4039760001')
```

### 7.35

```sql
select
    mpluto_bbl,
    st_isvalidreason(geom)
from
    nyc_building_footprints
where
    mpluto_bbl in ('1022430261', '1016710039', '4039760001')
```

### 7.36

```sql
select
    mpluto_bbl,
    st_isvalid(st_makevalid(geom))
from
    nyc_building_footprints
where
    mpluto_bbl in ('1022430261', '1016710039', '4039760001')
```

### 7.37

```sql
select
    st_srid(geom)
from
    nyc_building_footprints
limit
    3
```

### 7.38

```sql
select
    ogc_fid,
    st_transform(geom, 2263) as geom
from
    nyc_building_footprints
limit
    3
```

## 7.10 Inputs

### 7.39

```sql
select
    st_geomfromtext('POINT(-73.9772294 40.7527262)', 4326) as geom
```

## 7.11 Outputs

### 7.40

```sql
select
    st_asgeojson(geom)
from
    nyc_building_footprints
limit
    3
```

### 7.41

```sql
select
    st_geomfromtext('POINT(-73.9772294 40.7527262)', 4326) as geom
```

### 7.42

```sql
select
    st_buffer(st_transform(geom, 4326) :: geography, -200)
from
    nyc_zips
limit
    10
```

### 7.43

```sql
select
    st_centroid(st_transform(geom, 4326) :: geography)
from
    nyc_zips
limit
    10
```

### 7.44

```sql
select
    st_transform(geom, 4326) as original,
    st_chaikinsmoothing(st_transform(geom, 4326), 1) as one,
    st_chaikinsmoothing(st_transform(geom, 4326), 5) as five
from
    nyc_zips
limit
    10
```

### 7.45

```sql
-- Find the first 50 trees in Fort Greene with the
-- Latitude and longitude columns
with a as (
    select
        latitude,
        longitude
    from
        nyc_2015_tree_census
    where
        nta_name = 'Fort Greene'
    limit
        50
), 

-- Turn the latitude/longitude columns into geometries
b as (
    select
        st_collect(
            buildpoint(longitude :: numeric, latitude :: numeric, 4326)
        ) as geom
    from
        a
)

-- Create multiple concave hulls with various concave-ness
-- and use UNION to turn them into a single table
select
    st_concavehull(geom, 0.1) as hull
from
    b
union
select
    st_concavehull(geom, 0.3) as hull
from
    b
union
select
    st_concavehull(geom, 0.7) as hull
from
    b
```

### 7.46

```sql
with a as (
    select
        latitude,
        longitude
    from
        nyc_2015_tree_census
    where
        nta_name = 'Fort Greene'
    limit
        50
), b as (
    select
        st_collect(
            buildpoint(longitude :: numeric, latitude :: numeric, 4326)
        ) as geom
    from
        a
)
select
    st_convexhull(geom) as hull
from
    b
```

### 7.47

```sql
select
    st_delaunaytriangles(st_transform(geom, 4326)) as triangles
from
    nyc_zips
where
    zipcode = '10009'
```

### 7.48

```sql
select
    st_generatepoints(st_transform(geom, 4326), 500) as points
from
    nyc_zips
where
    zipcode = '10009'
```

### 7.49

```sql
select
st_linemerge(geom) as geom from
nyc_bike_routes
where
street = '7 AV'
and fromstreet = '42 ST'
and tostreet = '65 ST'
```

### 7.50

```sql
-- Create multiple geometries with different simplification levels
-- and UNION them into one table
select
    st_transform(geom, 4326) as geom
from
    nyc_zips
where
    zipcode = '11693'
union
select
    st_transform(st_simplify(geom, 1), 4326) as geom
from
    nyc_zips
where
    zipcode = '11693'
union
select
    st_transform(st_simplify(geom, 10), 4326) as geom
from
    nyc_zips
where
    zipcode = '11693'
union
select
    st_transform(st_simplify(geom, 50), 4326) as geom
from
    nyc_zips
where
    zipcode = '11693'
```

### 7.51

```sql
-- Create multiple geometries that share borders with different 
-- simplification levels and UNION them into one table
select
    st_transform(geom, 4326) as geom
from
    nyc_zips
where
    zipcode = '11434'
    or st_touches(
        geom,
        (
            select
                geom
            from
                nyc_zips
            where
                zipcode = '11434'
        )
    )
union
select
    st_transform(st_simplifypreservetopology(geom, 1), 4326) as geom
from
    nyc_zips
where
    zipcode = '11434'
    or st_touches(
        geom,
        (
            select
                geom
            from
                nyc_zips
            where
                zipcode = '11434'
        )
    )
union
select
    st_transform(st_simplifypreservetopology(geom, 10), 4326) as geom
from
    nyc_zips
where
    zipcode = '11434'
    or st_touches(
        geom,
        (
            select
                geom
            from
                nyc_zips
            where
                zipcode = '11434'
        )
    )
union
select
    st_transform(st_simplifypreservetopology(geom, 50), 4326) as geom
from
    nyc_zips
where
    zipcode = '11434'
    or st_touches(
        geom,
        (
            select
                geom
            from
                nyc_zips
            where
                zipcode = '11434'
        )
    )
```

## 7.12 Measurements in spatial SQL

### 7.52

```sql
select
    st_area(geom) as area
from
    nyc_building_footprints
limit
    5
```

### 7.53

```sql
select
    st_area(geom :: geography) as area
from
    nyc_building_footprints
limit
    5
```

### 7.54

```sql
with one as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10009'
),
two as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    st_closestpoint(one.geom, two.geom) as point
from
    one,
    two
```

### 7.55

```sql
with one as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10009'
),
two as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    st_distance(one.geom, two.geom) as dist
from
    one,
    two
```

### 7.56

```sql
with one as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10009'
),
two as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    st_distance(one.geom, two.geom) / 5280 as dist
from
    one,
    two
```

### 7.57

```sql
with one as (
    select
        geom :: geography as geog
    from
        nyc_zips
    where
        zipcode = '10009'
),
two as (
    select
        geom :: geography as geog
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    st_distance(one.geog, two.geog) / 1609 as dist
from
    one,
    two
```

### 7.58

```sql
select
    st_srid(geom)
from
    nyc_zips
limit
    1   
```

### 7.59

```sql
with one as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10009'
),
two as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    st_transform(st_shortestline(one.geom, two.geom), 4326) as line
from
    one,
    two
```

### 7.60

```sql
select
    st_length(geom :: geography)
from
    nyc_bike_routes
limit
    1
```

### 7.61

```sql
select
    st_perimeter(geom)
from
    nyc_zips
where
    zipcode = '10009'
```

### 7.62

```sql
with one as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10009'
),
two as (
    select
        geom
    from
        nyc_zips
    where
        zipcode = '10001'
)
select
    st_transform(st_shortestline(one.geom, two.geom), 4326) as line
from
    one,
    two
```
