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