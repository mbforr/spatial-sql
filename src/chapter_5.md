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

## SQL Data Types

### 5.7

```sql
select
    complaint_type,
    location_type,
    city
from
    nyc_311
limit
    5
```

### 5.8

```sql
select
    complaint_type,
    location_type,
    city
from
    nyc_311
where
    city = 'Brooklyn'
limit
    5
```

### 5.9

```sql
select
    complaint_type,
    location_type,
    city,
    city = 'BROOKLYN'
from
    nyc_311
limit
    5
```

## 5.4 Charecters

### 5.10

```sql
select
    spc_common,
    nta_name, health
from
    nyc_2015_tree_census
limit
    5
```

### 5.11

```sql
select
    spc_common || ' - ' || health as joined
from
    nyc_2015_tree_census
limit
    5
```

### 5.12

```sql
select
    concat(spc_common, ' - ', health)
from
    nyc_2015_tree_census
limit
    5
```

### 5.13

```sql
select
    spc_common,
    left(spc_common, 5) as left,
    right(spc_common, 3) as right
from
    nyc_2015_tree_census
limit
    5
```

### 5.14

```sql
select
    spc_common,
    initcap(spc_common) as titlecase,
    upper(spc_common) as uppercase,
    lower(spc_common) as lowercase
from
    nyc_2015_tree_census
limit
    5
```

### 5.15

```sql
select
    spc_common,
    replace(spc_common, 'locust', ' locust') as new_text
from
    nyc_2015_tree_census
limit
    5
```

### 5.16

```sql
select
    spc_common,
    reverse(spc_common) as backwards
from
    nyc_2015_tree_census
limit
    5
```

### 5.17

```sql
select
    spc_common,
    length(spc_common) as how_long
from
    nyc_2015_tree_census
limit
    5
```

### 5.18

```sql
select
    spc_common,
    split_part(spc_common, ' ', 2) as tree_group
from
    nyc_2015_tree_census
limit
    5
```

### 5.19

```sql
select
	spc_common,
	split_part(
		replace(spc_common, 'locust', ' locust'),
		' ',
		2
	) as tree_group
from
	nyc_2015_tree_census
limit
	5
```

## 5.5 Numeric

### 5.20

```sql
select
    total_amount,
    tip_amount,
    tip_amount /(total_amount - tip_amount) as tip_percent
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

## 5.6 Dates and Times

### 5.21

```sql
select
    pickup_datetime,
    dropoff_datetime
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

### 5.22

```sql
select
    to_char(pickup_datetime, 'DD Mon YYYY') as start_date,
    to_char(dropoff_datetime, 'DD Mon YYYY') as end_date
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

### 5.23

```sql
select
    to_char(pickup_datetime, 'D Month YYYY') as start_date,
    to_char(dropoff_datetime, 'D Month YYYY') as end_date
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

### 5.24

```sql
select
    to_char(pickup_datetime, 'Day, Month FMDDth, YYYY') as start_date,
    to_char(dropoff_datetime, 'Day, Month FMDDth, YYYY ') as end_date
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

### 5.25

```sql
select
    dropoff_datetime - pickup_datetime as duration
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

### 5.26

```sql
select
    extract(
        dow
        from
            pickup_datetime
    ) as day_of_week,
    extract(
        hour
        from
            pickup_datetime
    ) as hour_of_day
from
    nyc_yellow_taxi_0601_0615_2016
where
    tip_amount > 0
    and trip_distance > 2
limit
    5
```

## 5.7 Other data types

### 5.27

```sql
with json_table as (
    select
        JSON(
            '{"first": "Matt",
            "last": "Forrest",
            "age": 35}'
        ) as data
)

select
    data
from
    json_table 
```

### 5.28

```sql
with json_table as (
    select
        JSON(
            '{"first": "Matt",
            "last": "Forrest",
            "age": 35}'
        ) as data
)
select
    data -> 'last'
from
    json_table
```

### 5.29

```sql
with json_table as (
    select
        JSON(
            '{
                "first": "Matt",
                "last": "Forrest",
                "age": 35,
                "cities": ["Minneapolis", "Madison", "New York City"],
                "skills": {"SQL": true, "Python": true, "Java": false}
            }'
        ) as data
)
select
    data
from
    json_table
```

### 5.30

```sql
with json_table as (
    select
        JSON(
            '{
                "first": "Matt",
                "last": "Forrest",
                "age": 35,
                "cities": ["Minneapolis", "Madison", "New York City"],
                "skills": {"SQL": true, "Python": true, "Java": false}
            }'
        ) as data
)
select
    data -> 'cities' -> 1 as city,
    data -> 'skills' -> 'SQL' as sql_skills
from
    json_table
```

### 5.31

```sql
select
    cast(zipcode as numeric)
from
    nyc_zips
limit
    3
```
### 5.32

```sql
select
    zipcode :: numeric
from
    nyc_zips
limit
    3
```

## 5.8 Basic SQL Operators

### 5.33

```sql
select
    *
from
    nyc_2015_tree_census
where
    health = 'Fair'
```

### 5.34

```sql
select
    *
from
    nyc_2015_tree_census
where
    stump_diam > 0
```

### 5.35

```sql
select
    *
from
    nyc_2015_tree_census
where
    stump_diam :: numeric > 0
```

### 5.36

```sql
select
    spc_common
from
    nyc_2015_tree_census
where
    spc_common > 'Maple'
```

### 5.37

```sql
select
    *
from
    public.nyc_311
where
    complaint_type = 'Illegal Fireworks'
    and city = 'BROOKLYN'
limit
    25
```

### 5.38

```sql
select
    *
from
    public.nyc_311
where
    complaint_type = 'Illegal Fireworks'
    or agency = 'NYPD'
limit
    25
```

### 5.39

```sql
select
    *
from
    nyc_311
where
    complaint_type IN ('Illegal Fireworks', 'Noise - Residential')
limit
    25
```

### 5.40

```sql
select
    *
from
    nyc_311
where
    complaint_type IN ('Illegal Fireworks', 'Noise - Residential')
    and descriptor IN ('Loud Music/Party', 'Banging/Pounding')
limit
    25
```

### 5.41

```sql
select
    *
from
    nyc_311
where
    complaint_type IN ('Illegal Fireworks', 'Noise - Residential')
    and descriptor NOT IN ('Loud Music/Party', 'Banging/Pounding')
limit
    25
```

### 5.42

```sql
select
    *
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:05:00'
```

### 5.43

```sql
-- All return true since it matches the exact word

select
    'maple' like '%maple', --true  
    'maple' like 'maple%', --true  
    'maple' like '%maple%' --true  
    
-- The first returns false since the phrase does not end in the word "maple" 
select  
    'maple syrup' like '%maple', --false  
    'maple syrup' like 'maple%', --true  
    'maple syrup' like '%maple%' --true   

-- The second returns false since the phrase does not begin with the word "maple"  

select  
    'red maple' like '%maple', --true  
    'red maple' like 'maple%', --false  
    'red maple' like '%maple%' --true
```

### 5.44

```sql
select
    spc_common
from
    public.nyc_2015_tree_census
where
    spc_common like '%maple%
```

### 5.45

```sql
SELECT
    'maple' like 'm___', --false
    'maple' like 'm____', --true 
    'maple' like 'm_____' --false
```

### 5.46

```sql
select
    *
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_longitude IS NULL
```

### 5.47

```sql
select
    distinct spc_common
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
limit
    5
```

## 5.9 Aggregates and GROUP BY

### 5.48

```sql
select
    nta_name,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
group by
    nta_name
limit
    5
```

### 5.49

```sql
select
    nta_name,
    problems,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
group by
    nta_name,
    problems
limit
    5
```

### 5.50

```sql
select
    nta_name,
    array_agg(distinct curb_loc),
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
group by
    nta_name
limit
    3
```

### 5.51

```sql
select
    nta_name,
    avg(stump_diam :: numeric)
from
    nyc_2015_tree_census
where
    stump_diam :: numeric > 0
group by
    nta_name
limit
    3
```

### 5.52

```sql
select
    passenger_count,
    avg(tip_amount) filter (
        where
            tip_amount > 5
    )
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:05:00'
group by
    passenger_count
```

### 5.53

```sql
select
    passenger_count,
    avg(tip_amount) filter (
        where
            tip_amount > 5
    ),
    count(ogc_fid)
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:05:00'
    and count(ogc_fid) > 50
group by
    passenger_count
```

### 5.54

```sql
select
    passenger_count,
    avg(tip_amount) filter (
        where
            tip_amount > 5
    ),
    count(ogc_fid)
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:05:00'
group by
    passenger_count
having
    count(ogc_fid) > 50
```

### 5.55

```sql
select
    passenger_count,
    tip_amount
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:05:00'
order by
    tip_amount desc
limit
    5
```

### 5.56

```sql
select
    nta_name,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
group by
    nta_name
order by
    count(ogc_fid) desc
limit
    5
```

### 5.57

```sql
select
    nta_name,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
group by
    nta_name
order by
    count(ogc_fid) desc
limit
    5 offset 5
```
