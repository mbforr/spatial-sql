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