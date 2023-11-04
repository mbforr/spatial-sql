# 10 - Advanced spatial analytics

## 10.1 Spatial data enrichment or area weighted interpolation

### 10.1

```sh
ogrinfo ACS_2021_5YR_BG_36_NEW_YORK.gdb ACS_2021_5YR_BG_36_NEW_YORK -geom=YES -so
```

### Other import code

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker
dbname=gis port=25432" ACS_2021_5YR_BG_36_NEW_YORK.gdb \
-dialect sqlite -sql "select GEOID as geoid, b01001e1 as population, B01002e1 as age from X01_AGE_AND_SEX" \
-nln nys_2021_census_block_groups_pop -lco GEOMETRY_NAME=geom
```

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \ dbname=gis port=25432" ACS_2021_5YR_BG_36_NEW_YORK.gdb \
-dialect sqlite -sql "select GEOID as geoid, B19001e1 as income from X19_INCOME" \ 
-nln nys_2021_census_block_groups_income -lco GEOMETRY_NAME=geom
```

```sh
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \
dbname=gis port=25432" ACS_2021_5YR_BG_36_NEW_YORK.gdb \
-dialect sqlite -sql "select SHAPE as geom, GEOID as geoid from ACS_2021_5YR_BG_36_NEW_YORK" \
-nln nys_2021_census_block_groups_geom -lco GEOMETRY_NAME=geom
```

### 10.3

```sql
update nyc_neighborhoods set geom = st_makevalid(geom) where st_isvalid(geom) is false
```

### 10.4

```sql
select
    neighborhood,

    -- These are the values from the cross join lateral
    a.pop,
    a.count,
    a.avg
from
    nyc_neighborhoods
    cross join lateral (
        select

            -- This selects the sum of all the intersecting areas
            -- populations using the proportional overlap calculation
            sum(
                population * (
                    st_area(st_intersection(geom, nyc_neighborhoods.geom)) / st_area(geom)
                )
            ) as pop,
            count(*) as count,

            -- This selects the average area overlapping area
            -- of all the intersecting areas
            avg(
                (
                    st_area(st_intersection(nyc_neighborhoods.geom, geom)) / st_area(geom)
                )
            ) as avg
        from
            nys_2021_census_block_groups
        where
            left(geoid, 5) in ('36061', '36005', '36047', '36081', '36085')
            and st_intersects(nyc_neighborhoods.geom, geom)
    ) a
order by
    a.pop desc
```











