# 7 - Using the GEOMETRY

## 7.2 GEOMETRY Types

### 7.2

```sql
select
   geom
from
   nyc_building_footprints
limit
   1
```

### 7.3

```sql
select
   st_astext(geom) as wkt
from
   nyc_building_footprints
limit
   5
```

### 7.4

```sql
insert into
    geometries
values
    ('point', st_geomfromtext('POINT(0 0)')),
    (
        'line',
        st_geomfromtext('LINESTRING(0 0,1 1,1 2)')
    ),
    (
        'polygon',
        st_geomfromtext(
            'POLYGON((0 0,4 0,4 4,0 4,0 0),(1 1, 2 1, 2 2, 1 2,1 1))'
        )
    )
```

### 7.5

```sql
insert into
    geometries
values
    (
        'multipoint',
        st_geomfromtext('MULTIPOINT((0 0),(1 2))')
    ),
    (
        'multiline',
        st_geomfromtext('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))')
    ),
    (
        'multipolygon',
        st_geomfromtext(
            'MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0),(1 1,2 1,2 2,1 2,1 1)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))'
        )
    ),
    (
        'geometry collection',
        st_geomfromtext(
            'GEOMETRYCOLLECTION(POINT(2 3),LINESTRING(2 3,3 4))'
        )
    )
```

### 7.6

```sql
select
    st_curvetoline(
        st_geomfromtext('CIRCULARSTRING(0 0, 4 0, 4 4, 0 4, 0 0)')
    ) as geom
```