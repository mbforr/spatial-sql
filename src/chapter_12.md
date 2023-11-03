# 12 - Working with raster data in PostGIS

## 12.1 Raster Ingest

### 12.1

```sh
docker run --name mini-postgis -p 35432:5432 --network="host" 
-v /Users/mattforrest/Documents/spatial-sql-book/raster:/mnt/mydata 
-e POSTGRES_USER=admin -e POSTGRES_PASSWORD=password -d postgis/postgis:15-master
```

### 12.2

```sh
raster2pgsql -s 4269 -I -C -M mnt/mydata/denver-elevation.tif -t 128x128 -F denver_elevation | psql -d gis -h 127.0.0.1 -p 25432 -U docker -W
```

### 12.3

```sql
select
    *
from
    denver_elevation_full
```

### 12.4

```sql
with c as (
    select
        (st_contour(rast, 1, 200.00)).*
    from
        denver_elevation
    where
        filename = 'denver-elevation.tif'
)
select
    st_transform(geom, 4326),
    id,
    value
from
    c
```

## 12.2 Interpolation

### 12.5

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker dbname=gis port=25432" nys_mesonet_202307.csv \ 
-dialect sqlite -sql 'select makepoint(cast("longitude [degrees_east]" as numeric), cast("latitude [degrees_north]" as numeric), 4326)  AS geom, * from nys_mesonet_202307' \ 
-nln nys_mesonet_202307 -lco GEOMETRY_NAME=geom
```

### 12.9

```sql
create table nys_mesonet_raster as with inputs as (
    select
        -- Sets the pixel size to 0.01 decimal degrees since
        -- we are using EPSG 4326
        0.01 :: float8 as pixelsize,

        -- Sets the smoothing algorithim from "gdal_grid"
        'invdist:power:5.5:smoothing:2.0' as algorithm,
        st_collect(

            -- Creates a geometry collection of our data and forces
            -- a Z coodrinate of the max temparature 
            st_force3dz(
                geom,
                case
                    when "apparent_temperature_max [degc]" = '' then null
                    else "apparent_temperature_max [degc]" :: numeric
                end
            )
        ) as geom,

        -- Expands the grid to add room aroung the edges
        st_expand(st_collect(geom), 0.5) as ext
    from
        nys_mesonet_202307
    where
        time_end = '2023-07-23 12:00:00 EDT'
),
sizes AS (
  SELECT
    ceil((ST_XMax(ext) - ST_XMin(ext)) / pixelsize) :: integer AS width,
    ceil((ST_YMax(ext) - ST_YMin(ext)) / pixelsize) :: integer AS height,
    ST_XMin(ext) AS upperleftx,
    ST_YMax(ext) AS upperlefty
  FROM
    inputs
)
SELECT

    -- Sets 1 as the raster ID since we only have one raster
    1 AS rid,
    ST_InterpolateRaster(

        -- The geometry collection that will be used to interpolate to the raster
        geom,

        -- The algorithim we defined
        algorithm,
        ST_SetSRID(

            -- This creates the band
            ST_AddBand(

                -- Creates the empty raster with our arguments from the previous CTEs
                ST_MakeEmptyRaster(width, height, upperleftx, upperlefty, pixelsize),

                -- Sets the default values as a 32 bit float
                '32BF'
            ),

            -- The SRID the raster will use
            ST_SRID(geom)
        )
    ) AS rast 
FROM
    sizes,
    inputs
```

## 12.3 Raster to H3

### 12.10

```sql
create table denver_ele_h3 as
select
    h3_lat_lng_to_cell(a.geom, 11) as h3,
    avg(val) as avg_ele
from
    (
        select
            r.*
        from
            denver_elevation,
            lateral ST_PixelAsCentroids(rast, 1) as r
    ) a
group by
    1
```

### 12.11

```sql
select
    r.*
from
    denver_elevation,
    lateral ST_PixelAsCentroids(rast, 1) as r
```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```


### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```


### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```


### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```


### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```

### 12.1

```sql

```