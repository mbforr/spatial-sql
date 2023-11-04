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


