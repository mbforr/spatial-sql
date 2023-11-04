# 5 - SQL Basics

## 5.2 ogr2ogr

### 5.1 

```sh
ogr2ogr \
    -f PostgreSQL PG:"host=localhost user=user password=password \
    dbname=geo" /Users/matt/Documents/spatial-sql-book/nyc_taxi_yellow_0616-07.parquet \
    -nln nyc_taxi_yellow_0616 -lco GEOMETRY_NAME=geom
```

### 5.2

```sh
docker run --rm -v /Users:/Users --network="host" osgeo/gdal 
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \
dbname=gis port=25432" \
/Users/mattforrest/Documents/spatial-sql-data/nyc_yellow_taxi_0601_0615_2016.parquet \
-nln nyc_yellow_taxi_0601_0615_2016 -lco GEOMETRY_NAME=geom
```

### 5.3

```sql
create table nyc_311 (
   id int primary key,
   created_date timestamp,
   closed_date timestamp,
   agency text,
   agency_name text,
   complaint_type text,
   descriptor text,
   location_type text,
   incident_zip text,
   incident_address text,
   street_name text,
   cross_street_1 text,
   cross_street_2 text,
   intersection_street_1 text,
   intersection_street_2 text,
   address_type text,
   city text,
   landmark text,
   facility_type text,
   status text,
   due_date timestamp,
   resolution_description text,
   resolution_action_updated_date timestamp,
   community_board text,
   bbl text,
   borough text,
   x_coordinate_planar numeric,
   y_coordinate_planar numeric,
   open_data_channel_type text,
   park_facility_name text,
   park_borough text,
   vehicle_type text,
   taxi_company_borough text,
   taxi_pickup_location text,
   bridge_highway_name text,
   bridge_highway_description text,
   road_ramp text,
   bridge_highway_segment text,
   latitude numeric,
   longitude numeric,
   location text
)
```

### 5.4

```sh
docker run --rm -v //Users:/Users --network="host" osgeo/gdal \
ogr2ogr -f PostgreSQL PG:"host=localhost user=docker password=docker dbname=gis" \
/Users/matt/Desktop/Desktop/spatial-sql-book/Building_Footprints.geojson 
\ -nln nyc_building_footprints -lco GEOMETRY_NAME=geom
```

### 5.5

```sh
docker run --rm -v //Users:/Users --network="host" osgeo/gdal \
ogr2ogr -f PostgreSQL PG:"host=localhost user=docker password=docker dbname=gis" \
/Users/matt/Desktop/Desktop/spatial-sql-book/2015_NYC_Tree_Census.geojson \
-nln nyc_2015_tree_census -lco GEOMETRY_NAME=geom
```

### 5.6

```sh
docker run --rm -v //Users:/Users --network="host" osgeo/gdal \
ogr2ogr -f PostgreSQL PG:"host=localhost user=docker password=docker dbname=gis" \
/Users/matt/Desktop/Desktop/spatial-sql-book/nyc_mappluto_22v3_shp/MapPLUTO.shp \
-nln nyc_mappluto -lco GEOMETRY_NAME=geom \
-nlt MULTIPOLYGON -mapFieldType Real=String
```