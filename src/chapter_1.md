# 3 - Setting up

## 3.4 Installing docker-postgis

### 3.1

```sql
select
    *
from
    cb_2018_us_county_500k
where
    statefp = '55'
```

### 3.2

```sql
select
    id,
    st_centroid(geom) as geom
from
    cb_2018_us_county_500k
where
    statefp = '55'
```

### 3.3

```sql
create
or relace view wi_centroids AS
select
    id,
    st_centroid(geom) as geom
from
    cb_2018_us_county_500k
where
    statefp = '55'
```