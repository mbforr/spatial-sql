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

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```

### 6.3 

```sql

```


### 6.3 

```sql

```