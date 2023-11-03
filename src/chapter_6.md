# 6 - Advanced SQL topics for spatial SQL

## 6.1 CASE/WHEN Conditionals

### 6.2

```sql
case
    when temp > 35 then 'Super Hot !'
    when temp between 30
    and 35 then 'Hot'
    when temp between 25
    and 30 then 'Pretty Warm'
    when temp between 20
    and 25 then 'Warm'
    when temp between 15
    and 20 then 'Cool / Warm'
    when temp between 10
    and 15 then 'Cool'
    when temp between 5
    and 10 then 'Chilly'
    when temp between 0
    and 5 then 'Cold'
    when temp between -5
    and 0 then 'Pretty Cold'
    when temp between -10
    and -5 then 'Very Cold'
    when temp between -15
    and -10 then 'Brrrrr'
    when temp > -15 then 'Frigid !'
    else null
end
```

### 6.3 

```sql
select
    spc_common,
    case
        when spc_common like '%maple%' then 'Maple'
        else 'Not a Maple'
    end as is_maple
from
    nyc_2015_tree_census
limit
    10
```

### 6.4

```sql
select
    fare_amount,
    tip_amount,
    case
        when tip_amount / fare_amount between.15
        and.2 then 'Good'
        when tip_amount / fare_amount between.2
        and.25 then 'Great'
        when tip_amount / fare_amount between.25
        and.3 then 'Amazing'
        when tip_amount / fare_amount >.3 then 'Awesome'
        else 'Not Great'
    end as tip_class
from
    nyc_yellow_taxi_0601_0615_2016
limit
    10
```

### 6.5

```sql
select
    nta_name,
    sum(
        case
            when spc_common like '%maple%' then 1
            else 0
        end
    ) just_maples,
    count(ogc_fid) as all_trees
from
    nyc_2015_tree_census
group by
    nta_name
limit
    5
```

## 6.2 Common Table Expressions (CTEs) and Subqueries

### 6.6 

```sql
select
    zipcode,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
    and zipcode in (
        select
            zipcode
        from
            nyc_zips
        where
            population > 100000
    )
group by
    zipcode
```

### 6.7 

```sql
select
    zipcode,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    spc_common like '%maple%'
    and zipcode in ('11226', '11368', '11373')
group by
    zipcode
```

### 6.8

```sql
select
    zipcode,
    count(ogc_fid)
from
    nyc_2015_tree_census
where
    zipcode = (
        select
            zipcode
        from
            nyc_zips
        order by
            population asc
        limit
            1
    )
group by
    zipcode
```

### 6.9

```sql
with lanes as (
    select
        ogc_fid,
        lanecount
    from
        nyc_bike_routes
    order by
        lanecount desc
    limit
        3
)
select
    *
from
    lanes
```

### 6.10 

```sql
with lanes as (
    select
        ogc_fid,
        lanecount
    from
        nyc_bike_routes
    order by
        lanecount desc
    limit
        3
), lanes_2 as (
    select
        ogc_fid,
        lanecount
    from
        nyc_bike_routes
    order by
        lanecount desc
    limit
        3 offset 12
)
select
    *
from
    lanes 

-- the UNION operator allows us to bring 
-- two tables with matching columns together  

union  
select
    *
from
    lanes_2
```

## 6.3 CRUD: Create, Read, Update, and Delete

### 6.12

```sql
create table test (city text, country text, size_rank numeric)
```

### 6.13 

```sql
insert into
    test (city, country, size_rank)
values
    ('Tokyo', 'Japan', 1),
    ('Delhi', 'India', 2),
    ('Shanghai', 'China', 3),
    ('São Paulo', 'Brazil', 4),
    ('Mexico City', 'Mexico', 5)
```

### 6.14 

```sql
alter table
    test
add
    column population numeric
```

### 6.15

```sql
alter table
    test rename column population to city_pop
```

### 6.16

```sql
alter table
    test
alter column
    city_pop type int
```

### 6.17

```sql
update
    test
set
    city = 'Ciudad de México'
where
    city = 'Mexico City'
```

### 6.18

```sql
alter table
    test rename to world_cities
```

### 6.19 

```sql
alter table
    world_cities drop column city_pop
```

### 6.20

```sql
delete from
    world_cities
where
    city = 'Tokyo'
```

### 6.21

```sql
drop table world_cities
```

## 6.4 Statistical functions

### 6.22 

```sql
select
    corr(assesstot :: numeric, lotarea :: numeric)
from
    nyc_mappluto
```

### 6.23 

```sql
select
    stddev_samp(lotarea :: numeric)
from
    nyc_mappluto
where
    borough = 'BK'
```

### 6.24

```sql
select
    var_samp(lotarea :: numeric)
from
    nyc_mappluto
where
    borough = 'BK'
```

### 6.25

```sql
select
    mode() within group (
        order by
            lotarea :: numeric desc
    )
from
    nyc_mappluto
where
    borough = 'BK'
```

### 6.26

```sql
select
    ogc_fid,
    tip_amount,
    percent_rank() over(
        order by
            tip_amount asc
    )
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:00:05'
    and tip_amount > 0
```

### 6.27 

```sql
select
    ogc_fid,
    tip_amount,
    rank() over(
        order by
            tip_amount asc
    )
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:00:05'
    and tip_amount > 0
```

### 6.28 

```sql
select
    ogc_fid,
    tip_amount,
    dense_rank() over(
        order by
            tip_amount asc
    )
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:00:05'
    and tip_amount > 0
```


### 6.29

```sql
select
    percentile_disc(0.25) within group (
        order by
            tip_amount
    ) as per_25,
    percentile_disc(0.5) within group (
        order by
            tip_amount
    ) as per_50,
    percentile_disc(0.75) within group (
        order by
            tip_amount
    ) as per_75
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime between '2016-06-10 15:00:00'
    and '2016-06-10 15:00:05'
    and tip_amount > 0
```

## 6.5 Windows

### 6.30

```sql
with taxis as (
    select
        sum(total_amount) as total,
        pickup_datetime :: date as date
    from
        nyc_yellow_taxi_0601_0615_2016
    group by
        pickup_datetime :: date
    order by
        pickup_datetime :: date asc
)
select
    date,
    total,
    avg(total) over (
        order by
            date rows between 2 preceding
            and current row
    )
from
    taxis
```

### 6.31

```sql
with taxis as (
    select
        sum(total_amount) as total,
        passenger_count,
        pickup_datetime :: date as date
    from
        nyc_yellow_taxi_0601_0615_2016
    group by
        pickup_datetime :: date,
        passenger_count
    order by
        pickup_datetime :: date asc,
        passenger_count desc
)
select
    date,
    total,
    passenger_count,
    sum(total) over (
        partition by passenger_count
        order by
            date rows between 2 preceding
            and current row
    )
from
    taxis
```

### 6.32

```sql
select
    avg(tip_amount / total_amount),
    extract(
        hour
        from
            pickup_datetime
    ) as hour_of_day
from
    nyc_yellow_taxi_0601_0615_2016
where
    pickup_datetime :: date = '2016-06-15'

    -- since we can't divide by 0 we will remove all amounts 
    -- that equal 0
    
    and total_amount > 0
group by
    extract(
        hour
        from
            pickup_datetime
    )
order by
    extract(
        hour
        from
            pickup_datetime
    ) asc
```

### 6.33

```sql
with taxis as (
    select
        avg(tip_amount / total_amount) as tip_percentage,
        date_trunc('hour', pickup_datetime) as day_hour
    from
        nyc_yellow_taxi_0601_0615_2016
    where
        total_amount > 5
    group by
        date_trunc('hour', pickup_datetime)
)
select
    day_hour,
    tip_percentage,
    avg(tip_percentage) over (
        order by
            day_hour asc rows between 5 preceding
            and current row
    ) as moving_average
from
    taxis
```

### 6.34

```sql
with taxis as (
    select
        sum(total_amount) as total,
        passenger_count,
        pickup_datetime :: date as date
    from
        nyc_yellow_taxi_0601_0615_2016
    group by
        pickup_datetime :: date,
        passenger_count
    order by
        pickup_datetime :: date asc,
        passenger_count desc
)
select
    date,
    total,
    passenger_count,
    sum(total) over (
        partition by passenger_count
        order by
            date
    )
from
    taxis
```

### 6.35

```sql
select
    row_number() over() as row_no,
    ogc_fid
from
    nyc_yellow_taxi_0601_0615_2016
limit
    5
```

### 6.36
```sql
select
    row_number() over(partition by pickup_datetime) as row_no,
    ogc_fid,
    pickup_datetime
from
    nyc_yellow_taxi_0601_0615_2016
limit
    5 offset 100000 -- using offset since the first part of the datasets has all passenger counts as 0
```

### 6.37

```sql
with taxis as (
    select
        sum(total_amount) as total,
        passenger_count,
        pickup_datetime :: date as date
    from
        nyc_yellow_taxi_0601_0615_2016
    group by
        pickup_datetime :: date,
        passenger_count
    order by
        pickup_datetime :: date asc,
        passenger_count desc
)
select
    date,
    total,
    passenger_count,
    total - lag(total, 1) over (
        partition by passenger_count
        order by
            date
    )
from
    taxis
```

## 6.6 Joins

### 6.38

```sql
select
    nyc_311.complaint_type,
    nyc_311.incident_zip,
    nyc_zips.population
from
    nyc_311
    join nyc_zips on nyc_311.incident_zip = nyc_zips.zipcode
limit
    5
```

### 6.39

```sql
select
    nyc_311.complaint_type,
    nyc_311.incident_zip,
    nyc_zips.population
from
    nyc_311
    join nyc_zips on nyc_311.incident_zip = nyc_zips.zipcode
where
    nyc_zips.population > 80000
limit
    5
```

### 6.40

```sql
select
    a.complaint_type,
    a.incident_zip,
    b.population
from
    nyc_311 a
    join nyc_zips b on a.incident_zip = b.zipcode
where
    b.population > 80000
limit
    5
```

### 6.41

```sql
with b as (select population, zipcode from nyc_zips limit 30)

select
    a.complaint_type,
    a.incident_zip,
    b.population
from
    nyc_311 a
    left join b on a.incident_zip = b.zipcode
limit
    5
```

### 6.42

```sql
with a as (
    select
        complaint_type,
        incident_zip
    from
        nyc_311
    limit
        30
)
select
    a.complaint_type,
    a.incident_zip,
    b.population
from
    a
    right join nyc_zips b on a.incident_zip = b.zipcode
limit
    5
```

### 6.43

```sql
with a as (
    select
        complaint_type,
        incident_zip
    from
        nyc_311
    limit
        30
), b as (
    select
        population,
        zipcode
    from
        nyc_zips
    limit
        30
)
select
    a.complaint_type,
    a.incident_zip,
    b.population
from
    a full
    outer join b on a.incident_zip = b.zipcode
limit
    100
```

### 6.44

```sql
with a as (
    select
        neighborhood
    from
        nyc_neighborhoods
    limit
        2
), b as (
    select
        population,
        zipcode
    from
        nyc_zips
    limit
        2
)
select
    a.neighborhood,
    b.population
from
    a
    cross join b
```

### 6.45

```sql
with a as (
    select
        neighborhood
    from
        nyc_neighborhoods
    limit
        2
), b as (
    select
        population,
        zipcode
    from
        nyc_zips
    limit
        2
)
select
    a.neighborhood,
    b.population
from
    a,
    b
```

### 6.46

```sql
with a as (
    select
        neighborhood
    from
        nyc_neighborhoods
    limit
        2
), b as (
    select
        population,
        zipcode
    from
        nyc_zips
    limit
        2
)
select
    a.neighborhood,
    b.population,
    b.population / 1000 as calculation
from
    a,
    b
```

### 6.47

```sql
with a as (
    select
        ogc_fid,
        zipcode :: text
    from
        nyc_mappluto
)
select
    count(a.ogc_fid),
    b.zipcode
from
    nyc_zips b
    join a using(zipcode)
group by
    b.zipcode
order by
    count(a.ogc_fid) desc
```

### 6.49

```sql
with a as (
    select
        ogc_fid,
        zipcode :: text
    from
        nyc_mappluto
    order by
        ogc_fid desc
    limit
        5000
), c as (
    select
        ogc_fid,
        zipcode
    from
        nyc_2015_tree_census
    order by
        ogc_fid desc
    limit
        5000
)
select
    count(a.ogc_fid) as buildings,
    -- count(c.ogc_fid) as trees,  
    b.zipcode
from
    nyc_zips b
    join a using(zipcode) 
    -- join c  
    -- using(zipcode)  
group by
    b.zipcode
order by
    count(a.ogc_fid) desc
```

### 6.50

```sql
with a as (
    select
        ogc_fid,
        zipcode :: text
    from
        nyc_mappluto
    order by
        ogc_fid desc
    limit
        5000
), c as (
    select
        ogc_fid,
        zipcode
    from
        nyc_2015_tree_census
    order by
        ogc_fid desc
    limit
        5000
)
select
    -- count(a.ogc_fid) as buildings, 
    count(c.ogc_fid) as trees,
    b.zipcode
from
    nyc_zips b 
    -- join a using(zipcode)  
    join c using(zipcode)
group by
    b.zipcode 
    -- order by count(a.ogc_fid) desc  
order by
    count(c.ogc_fid) desc
```

### 6.51

```sql
with a as (
    select
        count(ogc_fid) as buildings,
        zipcode :: text
    from
        nyc_mappluto
    group by
        zipcode
),
b as (
    select
        count(ogc_fid) as trees,
        zipcode
    from
        nyc_2015_tree_census
    group by
        zipcode
)
select
    a.buildings,
    b.trees,
    c.zipcode
from
    nyc_zips c
    join a using(zipcode)
    join b using(zipcode)
order by
    b.trees desc
```

## 6.7 Lateral Joins

### 6.52

```sql
select
    a.neighborhood,
    trees.trees_per_sq_meter
from
    nyc_neighborhoods a
    cross join lateral (
        select
            count(ogc_fid) / a.area :: numeric as trees_per_sq_meter
        from
            nyc_2015_tree_census
        where
            a.neighborhood = neighborhood
    ) trees
order by
    trees.trees_per_sq_meter desc

```

## 6.8 Triggers

### 6.53

```sql
create table cities (
    city text,
    country text,
    size_rank numeric,
    time_zone text,
    time_zone_abbrev text
)
```

### 6.54

```sql
create
or replace function set_timezones() returns trigger language plpgsql as $$ begin
update
    cities
set
    time_zone = a.name,
    time_zone_abbrev = a.abbrev
from
    pg_timezone_names a
where
    a.name like '%' || replace(city, ' ', ' _ ') || '%';

return new;

end;

$$
```

### 6.55

```sql
create trigger update_city_tz
after
insert
    on cities for each row execute procedure set_timezones();
```

### 6.56

```sql
insert into
    cities (city, country, size_rank)
values
    ('Tokyo', 'Japan', 1),
    ('Delhi', 'India', 2),
    ('Shanghai', 'China', 3),
    ('São Paulo', 'Brazil', 4),
    ('Mexico City', 'Mexico', 5)
```

### 6.57

```sql
create
or replace function set_timezones() returns trigger language plpgsql as $$ begin
update
    cities
set
    time_zone = data.name,
    time_zone_abbrev = data.abbrev
from
    (
        select
            name,
            abbrev
        from
            pg_timezone_names
        where
            name like '%' || replace(city, ' ', '_') || '%'
    ) as data;

return new;

end;

$$
```

## 6.9 UDFs

### 6.59

```sql
create
or replace function tip_percentage(tip_column float, total_column float) 
returns numeric 
language plpgsql 
as $$ 

declare tip_percentage numeric;

begin if total_column = 0 then tip_percentage = 0;

elsif total_column is null then tip_percentage = 0;

elsif total_column > 0 then tip_percentage = tip_column / total_column;

end if;

return tip_percentage;

end;

$$
```

### 6.60

```sql
select
    total_amount,
    tip_amount,
    tip_percentage(tip_amount, total_amount)
from
    nyc_yellow_taxi_0601_0615_2016
order by
    pickup_datetime desc
limit
    10 offset 10000
```

### 6.61

```sql

```

### 6.62

```sql
select
    *
from
    find_311_text_match('food')
limit
    5
```
