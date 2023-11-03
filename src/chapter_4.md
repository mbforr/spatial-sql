# 4 - Thinking in SQL

### 4.3 Database organization and design

### 4.1

```sql
select
  name,

  -- Use the length() function to find the number of letters, or length of the name
  length(name),

  -- Use the pg_column_size() function to find the size of the column in bytes
  pg_column_size(name),

  -- Here we are doing a few things
  -- 1. Getting the size of the geom column in bytes using ST_MemSize()
  -- 2. Casting the result of ST_MemSize() to a numeric value since 
  --    ST_MemSize() to format it as a number implicitly
  -- 3. Use pg_size_pretty() to format the bytes in human readable sizes like kb or mb
  pg_size_pretty(st_memsize(geom) :: numeric)
from
  cb_2018_us_county_500k 

  -- Using order by to order the results of ST_MemSize() 
  -- from largest to smallest, or descending using desc
order by
  st_memsize(geom) desc
```

### 4.2

```sql
select
  name,

  -- Calculate the total number of points in the geometry using ST_NPoints()
  st_npoints(geom) as n_points,

  -- Calculate the size of the geometry using ST_MemSize()
  st_memsize(geom) as size_bytes,
  
  -- Using the formula we saw, calculate the size of the geometry as: 40 + ( no. of points * 16)
  40 + (16 * st_npoints(geom)) as calculated_size
from
  cb_2018_us_county_500k
order by
  st_memsize(geom) desc
```

### 4.3

```sql
select
  name,

  -- Use ST_GeometryType to see our geometry type
  st_geometrytype(geom) as geom_type,
  st_memsize(geom) as size_bytes,

  -- Use ST_NumGeometries to see our geometry type
  st_numgeometries(geom) as num_geoms,
  
  -- Try and calculate using the formula (no. of geometries * 40) + (no. of points * 16)
  (st_numgeometries(geom) * 40) + (16 * st_npoints(geom)) as calculated_size
from
  cb_2018_us_county_500k
order by
  st_memsize(geom) desc
```
### 4.4

```sql
select
  name,
  st_geometrytype(geom) as geom_type,
  st_memsize(geom) as size_bytes,
  st_numgeometries(geom) as num_geoms,

  -- Try and calculate using the formula 32 + ((no. of geometries * 16) + (no. of points * 16))
  
  32 + (
    (st_numgeometries(geom) * 16) + (16 * st_npoints(geom))
  ) as calculated_size
from
  cb_2018_us_county_500k
order by
  st_memsize(geom) desc
```
### 4.5

```sql
select
    pc.geom,
    pc.postal_code,
    count(customers.customer_id)
from
    postal_codes pc
    join customers using (postal_code)
group by
    pc.postal_code
```

### 4.6

```sql
select
    *
from
    street_centerlines_current
where
    date_added between '01-01-2022'
    and '06-30-2022'
```

## 4.5 Projections

### 4.7

```sql
insert into
    spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext)
values
    (
        104726,
        'ESRI',
        104726,
        '+proj=longlat +a=6378418.941 +rf=298.257222100883 +no_defs +type=crs',
        'GEOGCS["GCS_NAD_1983_HARN_Adj_MN_Hennepin",DATUM["D_NAD_1983_HARN_Adj_MN_Hennepin",SPHEROID["S_GRS_1980_Adj_MN_Hennepin",6378418.941,298.257222100883,AUTHORITY["ESRI","107726"]],AUTHORITY["ESRI","106726"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["ESRI","104726"]]'
    );
```

### 4.8

```sql
create view mn_104726 as
select
  id,
  st_transform(geom, 104726)
from
  cb_2018_us_county_500k
where
  statefp = '27'
```

## 4.6 Thinking in SQL

### 4.9

```sql
-- First we select your data from the ZIP codes table 
-- and aggregate or count the total number of records 
-- from the NYC 311 data
select
  zips.zipcode,
  zips.geom,
  count(nyc_311.*) as count
  
-- Then we join the tables on a common ID, in this case the ZIP code
from
  nyc_zips zips
  join nyc_311 on nyc_311.incident_zip = zips.zipcode 
  
-- Then we filter using WHERE to the right complaint type 
-- and group the results by the ZIP code and geometry
where
  nyc_311.complaint_type = 'Illegal Parking'
group by
  zips.zipcode,
  zips.geom
```

## 4.7 Optimizing our queries and other tips

### 4.10

```sql
select
    zips.zipcode,
    zips.geom,
    count(nyc_311.id) as count
from
    nyc_zips zips
    join nyc_311 on nyc_311.incident_zip = zips.zipcode
where
    nyc_311.complaint_type = 'Illegal Parking'
group by
    zips.zipcode,
    zips.geom
```

### 4.11

```sql
-- In this CTE, which has an alias of "a", 
-- we pull the data we need from the nyc_311 data 
-- and filter to just the results that match "Illegal Parking"
with a as (
  select
    id,
    incident_zip as zipcode
  from
    nyc_311
  where
    nyc_311.complaint_type = 'Illegal Parking'
) 

-- We then join the data from our "temporary table" a to the zipcode data
select
  zips.zipcode,
  zips.geom,
  count(a.id) as count
from
  nyc_zips zips
  join a using (zipcode)
group by
  zips.zipcode,
  zips.geom
```

### 4.12

```sql
-- Now we have our entire aggregation in the CTE
with a as (
    select
        count("unique key") as total,
        "incident zip" as zipcode
    from
        nyc_311
    where
        nyc_311."complaint type" = 'Illegal Parking'
    group by
        "incident zip"
)
select
    zips.zipcode,
    zips.geom,
    a.total
from
    nyc_zips zips
    join a using (zipcode)
```

## 4.8 Using pseudo-code and "rubber ducking"

### 4.13

```sql
select
    *
from
    nyc_311
where
    DATE_PART('month', "created date") = 7
    and "complaint type" = 'Illegal Fireworks'
```

### 4.14

```sql
select
    *
from
    nyc_311
where
    date_part('month', "created date" :: date) = 7
    and "complaint type" = 'Illegal Fireworks'
```