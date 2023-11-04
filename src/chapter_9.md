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