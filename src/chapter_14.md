# 14 - Spatial autocorrelation and optimization with Python and PySAL

## 14.1 Spatial autocorrelation

### Shell commands

```sql
CREATE EXTENSION plpython3u;
```

```sh
docker container exec -it docker-postgis-db-1 bash
```

```sh
apt update
```

```sh
apt install python3-pip
```

```sh
python3 --version
pip3 --version
```

```sh
apt-get install gdal-bin
apt-get install libgdal-dev
```

```sh
pip3 install esda matplotlib libpysal spopt geopandas scikit-learn --break-system-packages
```

### 14.1

```sql
CREATE FUNCTION pymax (a integer, b integer) 
RETURNS integer 
AS $$ 
    if a > b: 
        return a 
    return b 
$$ 
LANGUAGE plpython3u;
```

### 14.2

```sql
select
    pymax(100, 1)
```

### 14.3

```sql
create function python_limit_5 (tablename TEXT) 
returns text
AS $$
	data = plpy.execute(f'''select * from {tablename} limit 5''')
	return data 
$$
LANGUAGE plpython3u;
```


```sql
create table nyc_neighborhoods_no_geom as
select
    ogc_fid,
    neighborhood,
    boroughcode,
    borough
from
    nyc_neighborhoods
```

### 14.5

```sql
create or replace function python_limit_5 (tablename TEXT) 
returns text 
AS $$ 
    data = plpy.execute(f'''select * from {tablename} limit 5''') 
    return data[0] 
$$ 
LANGUAGE plpython3u;
```

### 14.7

```sql
create or replace function python_limit_5 (tablename TEXT) 
returns text 
AS $$ 
    data = plpy.execute(f'''select * from {tablename} limit 5''') 
    return data[0]['neighborhood'] 
$$ 
LANGUAGE plpython3u;
```

### 14.8

```sql
create
or replace function pysal_esda_test(
    tablename TEXT,
    geom TEXT,
    col TEXT,
    id_col TEXT,
    similarity FLOAT
) 
returns text 
AS $$ 
    import esda 
    import libpysal as lps 
    from libpysal.weights import W 
    import json 
    import numpy as np 
    import pandas as pd 
    
    neighbors = plpy.execute(
        f '''
        select
            json_object_agg(b.{ id_col }, a.neighbors) as neighbors
        from
            { tablename } b
            cross join lateral (
                select
                    array_agg(z.{ id_col } :: text) as neighbors
                from
                    { tablename } z
                where
                    st_intersects(z.{ geom }, b.{ geom })
                    and z.{ id_col } != b.{ id_col }
            ) a
        where
            a.neighbors is not null  
        '''
    ) 
    
    weights = plpy.execute(
        f ''' 
        select
            json_object_agg(b.{ id_col }, a.weights) as weights
        from
            { tablename } b
            cross join lateral (
                select
                    array_agg(z.{ id_col }) as neighbors,
                    array_fill(
                        (
                            case
                                when count(z.{ id_col }) = 0 then 0
                                else 1 / count(z.{ id_col }) :: numeric
                            end
                        ),
                        array [count(z.{id_col})::int]
                    ) as weights
                from
                    { tablename } z
                where
                    st_intersects(z.{ geom }, b.{ geom })
                    and z.{ id_col } != b.{ id_col }
            ) a
        where
            a.neighbors is not null
        '''
    ) 
    return neighbors 
$$ 
LANGUAGE 'plpython3u';
```

### 14.17

```sql
create
or replace function pysal_esda_test(
    tablename TEXT,
    geom TEXT,
    col TEXT,
    id_col TEXT,
    similarity FLOAT
) 
returns text 
AS $$ 
    import esda 
    import libpysal as lps 
    from libpysal.weights import W 
    import json 
    import numpy as np 
    import pandas as pd 
    
    neighbors = plpy.execute(
        f '''
        select
            json_object_agg(b.{ id_col }, a.neighbors) as neighbors
        from
            { tablename } b
            cross join lateral (
                select
                    array_agg(z.{ id_col } :: text) as neighbors
                from
                    { tablename } z
                where
                    st_intersects(z.{ geom }, b.{ geom })
                    and z.{ id_col } != b.{ id_col }
            ) a
        where
            a.neighbors is not null  
        '''
    ) 
    
    weights = plpy.execute(
        f ''' 
        select
            json_object_agg(b.{ id_col }, a.weights) as weights
        from
            { tablename } b
            cross join lateral (
                select
                    array_agg(z.{ id_col }) as neighbors,
                    array_fill(
                        (
                            case
                                when count(z.{ id_col }) = 0 then 0
                                else 1 / count(z.{ id_col }) :: numeric
                            end
                        ),
                        array [count(z.{id_col})::int]
                    ) as weights
                from
                    { tablename } z
                where
                    st_intersects(z.{ geom }, b.{ geom })
                    and z.{ id_col } != b.{ id_col }
            ) a
        where
            a.neighbors is not null
        '''
    )  
    
    w = W(json.loads(neighbors [0] ['neighbors']), json.loads(weights [0] ['weights']), silence_warnings = True) 
    w.transform = 'r' 
    
    var_data = plpy.execute(
        f '''
        with a as (
            select
                distinct b.{ col },
                b.{ id_col }
            from
                { tablename } b
                cross join lateral (
                    select
                        array_agg(z.{ id_col }) as neighbors
                    from
                        { tablename } z
                    where
                        st_intersects(z.{ geom }, b.{ geom })
                        and z.{ id_col } != b.{ id_col }
                ) a
            where
                a.neighbors is not null
        )
        select
            { col } as data_col
        from
            a
        ''') 
    
    var_list = [] 
    for i in var_data: 
        if i ['data_col'] == None: 
            var_list.append(float(0.0))
        else: 
            var_list.append(float(i ['data_col'])) 
    
    li = esda.moran.Moran_Local(np.array(var_list), w) 
    
    return var_list 
$$ 
LANGUAGE 'plpython3u';
```

### 14.22

```sql
create or replace function pysal_esda (
    tablename TEXT, 
    geom TEXT, 
    col TEXT, 
    id_col TEXT, 
    similarity FLOAT
)
returns table (
    id TEXT, 
    col FLOAT, 
    local_morani_values FLOAT, 
    p_values FLOAT, 
    quadrant TEXT, 
    geom GEOMETRY
)
AS $$ 
    import esda 
    import libpysal as lps 
    from libpysal.weights import W 
    import json 
    import numpy as np 
    import pandas as pd 
    
    neighbors = plpy.execute(
        f'''
        select
            json_object_agg(b.{id_col}, a.neighbors) as neighbors
        from
            {tablename} b
            cross join lateral (
                select
                    array_agg(z.{id_col} :: text) as neighbors
                from
                    {tablename} z
                where
                    st_intersects(z.{geom}, b.{geom})
                    and z.{id_col} != b.{id_col}
            ) a
        where
            a.neighbors is not null  
        '''
    ) 
    
    weights = plpy.execute(
        f''' 
        select
            json_object_agg(b.{id_col}, a.weights) as weights
        from
            {tablename} b
            cross join lateral (
                select
                    array_agg(z.{id_col}) as neighbors,
                    array_fill(
                        (
                            case
                                when count(z.{id_col}) = 0 then 0
                                else 1 / count(z.{id_col}) :: numeric
                            end
                        ),
                        array [count(z.{id_col})::int]
                    ) as weights
                from
                    {tablename} z
                where
                    st_intersects(z.{geom}, b.{geom})
                    and z.{id_col} != b.{id_col}
            ) a
        where
            a.neighbors is not null
        '''
    )  
    
    w = W(json.loads(neighbors[0]['neighbors']), json.loads(weights[0]['weights']), silence_warnings = True) 
    w.transform = 'r' 
    
    var_data = plpy.execute(
        f'''
        with a as (
            select
                distinct b.{col},
                b.{id_col}
            from
                {tablename} b
                cross join lateral (
                    select
                        array_agg(z.{id_col}) as neighbors
                    from
                        {tablename} z
                    where
                        st_intersects(z.{geom}, b.{geom})
                        and z.{id_col} != b.{id_col}
                ) a
            where
                a.neighbors is not null
        )
        select
            {col} as data_col
        from
            a
        ''') 
    
    var_list = [] 
    for i in var_data: 
        if i['data_col'] == None: 
            var_list.append(float(0.0))
        else: 
            var_list.append(float(i['data_col'])) 
    
    li = esda.moran.Moran_Local(np.array(var_list), w)  
    
    original = plpy.execute(f'''
    with a as (
        select
            distinct b.{col},
            b.{id_col},
            b.{geom}
        from
            {tablename} b
            cross join lateral (
                select
                    array_agg(z.{id_col}) as neighbors
                from
                    {tablename} z
                where
                    st_intersects(z.{geom}, b.{geom})
                    and z.{id_col} != b.{id_col}
            ) a
        where
            a.neighbors is not null
    )
    select
        {id_col},
        {col},
        {geom}
    from
        a'''
    ) 
    
    original_data = [] 
    lookup_table = [] 
    
    for i in original: 
        original_data.append(i) 
        lookup_table.append(i[f'{id_col}']) 

    df = pd.DataFrame.from_dict(original_data) 
    
    formatted_data = [] 
	
    for i in original_data: 
        dict = i 
        res = lookup_table.index(i[f'{id_col}']) 
        dict['local_morani_values'] = li.Is[res] 
        dict['p_values'] = li.p_sim[res] 
        dict['quadrant'] = li.q[res] 
        formatted_data.append(dict) 
    
    original_data_df = pd.DataFrame.from_dict(formatted_data) 
    final = df.merge(original_data_df, how='inner', on=f'{id_col}') 
    final_df = final.drop([f'{col}_x', f'{geom}_x'], axis=1) 
    final_df = final_df.rename(columns = {f'{col}_y': 'col', f'{geom}_y': f'{geom}', f'{id_col}': 'id'}) 
    
    return final_df.to_dict(orient = 'records')
$$ 
LANGUAGE 'plpython3u';
```

### 14.23

```sql
create table nyc_2021_census_block_groups_morans_i as
select
    *
from
    nys_2021_census_block_groups
where
    left(geoid, 5) in ('36061', '36005', '36047', '36081', '36085')
    and population > 0
```

### 14.24

```sql
create table nyc_bgs_esda as
select
    *
from
    pysal_esda(
        'nyc_2021_census_block_groups_morans_i',
        'geom',
        'income',
        'geoid',
        0.05
    )
```

## 14.2 Location allocation

### 14.25

```sh
ogr2ogr \ 
-f PostgreSQL PG:"host=localhost user=docker password=docker dbname=routing port=25432" \
FDNY_Firehouse_Listing.csv \ 
-dialect sqlite -sql \
"select *, makepoint(cast(Longitude as float), cast(Latitude as float), 4326) as geom from FDNY_Firehouse_Listing" \ 
-nln nyc_fire_stations -lco GEOMETRY_NAME=geom
```

### 14.26

```sql
ogr2ogr \ 
-f PostgreSQL PG:"host=localhost user=docker password=docker \
dbname=routing port=25432" nyc_mappluto_22v3_shp/MapPLUTO.shp \ 
-nln building_footprints -lco GEOMETRY_NAME=geom \
-nlt MULTIPOLYGON -mapFieldType Real=String
```

### 14.27

```sql
ogr2ogr \
-f PostgreSQL PG:"host=localhost user=docker password=docker \
dbname=routing port=25432" \
-dialect SQLite -sql "SELECT neighborhood, boroughcode, borough, \
ST_Area(st_collect(st_transform(geometry, 3857))) AS area, \
st_collect(geometry) as geom FROM nyc_hoods \
group by neighborhood, boroughcode, borough" \
nyc_hoods.geojson \
-nln nyc_neighborhoods -lco GEOMETRY_NAME=geom -nlt PROMOTE_TO_MULTI
```

### 14.28

```sql
create table new_stations (name text, geom geometry)
```

### 14.29

```sql
insert into
    new_stations (name, geom)
values
    (
        'Withers and Woodpoint',
        st_setsrid(st_makepoint(-73.941455, 40.717628), 4326)
    ),
    (
        'Grand and Graham',
        st_setsrid(st_makepoint(-73.943791, 40.711584), 4326)
    ),
    (
        'Berry and N 11th',
        st_setsrid(st_makepoint(-73.9566498, 40.7207395), 4326)
    )
```

### 14.30

```sql
create table all_stations as
select
    facilityname as name,
    geom
from
    nyc_fire_stations
where

    -- Finding all the stations in our three target neighborhoods
    st_intersects(
        geom,
        (
            select
                st_union(st_transform(geom, 4326))
            from
                nyc_neighborhoods
            where
                neighborhood in (
                    'Williamsburg',
                    'East Williamsburg',
                    'Greenpoint'
                )
        )
    )
union
select
    *
from
    new_stations
```

### 14.31

```sql
create table bk_blgds as
select
    *
from
    building_footprints
where
    st_intersects(
        st_transform(geom, 4326),

        -- Find all the buildings that are in the three neighborhoods
        -- and within 100 meters
        (
            select
                st_buffer(st_union(geom) :: geography, 100) :: geometry
            from
                nyc_neighborhoods
            where
                neighborhood in (
                    'Williamsburg',
                    'East Williamsburg',
                    'Greenpoint'
                )
        )
    )
```

### 14.32

```sql
create table fire_odm as 
with starts as (

    -- Aggregate the source way ID into an array for
    -- the closest way ID to each station
    select
        array_agg(z.source)
    from
        all_stations
        cross join lateral (
            select
                source
            from
                ways
                join car_config c using (tag_id)
            where

                -- Here we are picking all the way tags that
                -- are not in this list
                c.tag_value not in (
                    'track',
                    'bridleway',
                    'bus_guideway',
                    'byway',
                    'cycleway',
                    'path',
                    'track',
                    'grade1',
                    'grade2',
                    'grade3',
                    'grade4',
                    'grade5',
                    'unclassified',
                    'footway',
                    'pedestrian',
                    'steps'
                )
            order by
                the_geom <-> all_stations.geom
            limit
                1
        ) z
), 

-- Here we do the same with the destinations for the buildings
destinations as (
    select
        array_agg(z.source)
    from
        bk_blgds
        cross join lateral (
            select
                source
            from
                ways
                join car_config c using (tag_id)
            where
                c.tag_value not in (
                    'track',
                    'bridleway',
                    'bus_guideway',
                    'byway',
                    'cycleway',
                    'path',
                    'track',
                    'grade1',
                    'grade2',
                    'grade3',
                    'grade4',
                    'grade5',
                    'unclassified',
                    'footway',
                    'pedestrian',
                    'steps'
                )
            order by
                ways.the_geom <-> st_transform(st_centroid(bk_blgds.geom), 4326)
            limit
                1
        ) z

    -- We only select the buildings in the neighborhood boundaries
    where
        st_intersects(
            st_transform(geom, 4326),
            (
                select
                    st_buffer(st_union(geom) :: geography, 100) :: geometry
                from
                    nyc_neighborhoods
                where
                    neighborhood in (
                        'williamsburg',
                        'east williamsburg',
                        'greenpoint'
                    )
            )
        )
)
select
    *
from

    -- Here we pass these arguments to the pgr_bdDijkstraCost function
    pgr_bddijkstracost(
        $$
        select
            id,
            source,
            target,
            cost_s as cost,
            reverse_cost_s as reverse_cost
        from
            ways
            join car_config using (tag_id)
        where
            st_intersects(
                st_transform(the_geom, 4326),
                (
                    select
                        st_buffer(st_union(geom) :: geography, 100) :: geometry
                    from
                        nyc_neighborhoods
                    where
                        neighborhood in (
                            'williamsburg',
                            'east williamsburg',
                            'greenpoint'
                        )
                )
            ) $$,

            -- We pass the arrays from above as the two arguments
            (
                select
                    *
                from
                    starts
            ),
            (
                select
                    *
                from
                    destinations
            ),
            true
    );
```

### 14.46

```sql
create
or replace function spopt_pmedian(
    odm_table TEXT,
    optimal_facilities INT,
    clients_table TEXT,
    facilities_table TEXT
)
returns table (
    facility TEXT,
    end_vid INT,
    ogc_fid INT,
    geom GEOMETRY
) AS $$
    import spopt 
    from spopt.locate import PMedian 
    import numpy 
    import pulp 
    import pandas as pd 

    odm = plpy.execute(f''' select * from {odm_table} ''')
    odm_new = [] 

    for i in odm: 
        odm_new.append({'start_vid': i['start_vid'], 'end_vid': i['end_vid'], 'agg_cost': i['agg_cost']})
        
    solver = pulp.PULP_CBC_CMD(keepFiles=True)

    df = pd.DataFrame.from_dict(odm_new) 
    data = df.pivot_table(index='end_vid', columns='start_vid', values='agg_cost', fill_value=1000000).values 
    vals = df.pivot_table(index='end_vid', columns='start_vid', values='agg_cost', fill_value=1000000)

    clients = data.shape[0] 
    weights = [1] * clients

    pmedian_from_cm = PMedian.from_cost_matrix(
        numpy.array(data), 
        numpy.array(weights),
        p_facilities=int(optimal_facilities), 
        name="p-median-network-distance" ) 

    pmedian_from_cm = pmedian_from_cm.solve(solver)

    station_ids = plpy.execute(f'''
    select
        z.source as end_vid,
        {facilities_table}.name
    from
        {facilities_table}
        cross join lateral (
            SELECT
                source
            FROM
                ways
                join configuration c using (tag_id)
            where
                c.tag_value not in (
                    'track',
                    'bridleway',
                    'bus_guideway',
                    'byway',
                    'cycleway',
                    'path',
                    'track',
                    'grade1',
                    'grade2',
                    'grade3',
                    'grade4',
                    'grade5',
                    'unclassified',
                    'footway',
                    'pedestrian',
                    'steps'
                )
            ORDER BY
                ways.the_geom <-> st_transform(st_centroid({facilities_table}.geom), 4326)
            limit
                1
        ) z
    ''') 

    stations = [] 

    for i in station_ids: 
        stations.append(i) 

    stations_df = pd.DataFrame.from_dict(stations)

    cleaned_points = []

    for i in pmedian_from_cm.fac2cli: 
        if len(i) > 0: 
            z = stations_df[stations_df['end_vid'] == vals.columns[pmedian_from_cm.fac2cli.index(i)]]['name'].values[0] 
            for j in i: 
                struct = {'facility': z, 'end_vid': list(vals.index)[j]} 
                cleaned_points.append(struct)

    df_startids = pd.DataFrame.from_dict(cleaned_points)

    orig_data = plpy.execute(f''' 
    select
        z.source as end_vid,
        {clients_table}.ogc_fid,
        st_transform(st_centroid({clients_table}.geom), 4326) as geom
    from
        {clients_table}
        cross join lateral (
            SELECT
                source
            FROM
                ways
                join car_config c using (tag_id)
            where
                c.tag_value not in (
                    'track',
                    'bridleway',
                    'bus_guideway',
                    'byway',
                    'cycleway',
                    'path',
                    'track',
                    'grade1',
                    'grade2',
                    'grade3',
                    'grade4',
                    'grade5',
                    'unclassified',
                    'footway',
                    'pedestrian',
                    'steps'
                )
            ORDER BY
                ways.the_geom <-> st_transform(st_centroid({clients_table}.geom), 4326)
            limit
                1
        ) z
    ''') 

    orig_formatted = [] 
    for i in orig_data: 
        orig_formatted.append(i) 

    orig_df = pd.DataFrame.from_dict(orig_formatted)

    final_df = orig_df.merge(df_startids, how='left', on='end_vid') 
    final_df = final_df.replace(numpy.nan, None) 

    return final_df.to_dict(orient='records')
$$ 
LANGUAGE 'plpython3u';
```

### 14.47

```sql
create table bk_final as
select
    *
from
    spopt_pmedian('fire_odm', 5, 'bk_blgds', 'all_stations');
```

### 14.48

```sql
create table final_stations as
select
    *
from
    all_stations
where
    name in (
        select
            distinct facility
        from
            bk_final
    )
```

## 14.3 Build balanced territories

### 14.59

```sql
create
or replace function pysal_skater(
    tablename TEXT,
    geometry TEXT,
    col TEXT,
    id_col TEXT,
    n_clusters INT,
    floor INT
) returns table (id TEXT, col FLOAT, regions INT, geometry TEXT) 
AS $$ 
    import spopt 
    import libpysal as lps 
    import json 
    import numpy as np 
    import pandas as pd 
    import geopandas as gpd
    from sklearn.metrics import pairwise as skm 
    import numpy
    from shapely import wkt 
    
    neighbors = plpy.execute(f'''
    select
        json_object_agg(b.{ id_col }, a.neighbors) as neighbors
    from
        { tablename } b
        cross join lateral (
            select
                array_agg(z.{ id_col } :: text) as neighbors
            from
                { tablename } z
            where
                st_intersects(z.{ geometry }, b.{ geometry })
                and st_npoints(st_intersection(b.{ geometry }, z.{ geometry })) > 1
                and z.{ id_col } != b.{ id_col }
        ) a
    where
        a.neighbors is not null
    ''')
   
    weights = plpy.execute(f'''
    select
        json_object_agg(b.{ id_col }, a.weights) as weights
    from
        { tablename } b
        cross join lateral (
            select
                array_agg(z.{ id_col }) as neighbors,
                array_fill(
                    (
                        case
                            when count(z.{ id_col }) = 0 then 0
                            else 1 / count(z.{ id_col }) :: numeric
                        end
                    ),
                    array [count(z.{id_col})::int]
                ) as weights
            from
                { tablename } z
            where
                st_intersects(z.{ geometry }, b.{ geometry })
                and st_npoints(st_intersection(b.{ geometry }, z.{ geometry })) > 1
                and z.{ id_col } != b.{ id_col }
        ) a
    where
        a.neighbors is not null
    ''')
    
    ids = [] 

    for i in json.loads(weights[0]['weights']): 
        ids.append(i) 

    w = lps.weights.W(json.loads(neighbors[0]['neighbors']), json.loads(weights[0]['weights']), silence_warnings = True, id_order=ids) 
    w.transform='r'

    to_gdf = plpy.execute(f'''
    select
        st_astext(st_transform({ geometry }, 4326)) as geometry,
        { col } :: numeric as col,
        { id_col } as id
    from
        { tablename } b
        cross join lateral (
            select
                array_agg(z.{ id_col }) as neighbors,
                array_fill(
                    (
                        case
                            when count(z.{ id_col }) = 0 then 0
                            else 1 / count(z.{ id_col }) :: numeric
                        end
                    ),
                    array [count(z.{id_col})::int]
                ) as weights
            from
                { tablename } z
            where
                st_intersects(z.{ geometry }, b.{ geometry })
                and st_npoints(st_intersection(b.{ geometry }, z.{ geometry })) > 1
                and z.{ id_col } != b.{ id_col }
        ) a
    where
        a.neighbors is not null
    ''')

    gdf_data = [] 

    for i in to_gdf: 
        gdf_data.append(i) 
        
    gdf = gpd.GeoDataFrame(gdf_data)

    spanning_forest_kwds = dict( 
        dissimilarity=skm.manhattan_distances, 
        affinity=None, 
        reduction=numpy.sum, 
        center=numpy.mean, 
        verbose=False
    )

    model = spopt.region.Skater(
        gdf, 
        w, 
        ['col'], 
        n_clusters=n_clusters, 
        floor=floor, 
        trace=False, 
        islands='increase', 
        spanning_forest_kwds=spanning_forest_kwds
    )
    
    model.solve() 
    
    gdf['regions'] = model.labels_
    
    return gdf.to_dict(orient = 'records') 
$$ 
LANGUAGE 'plpython3u';
```

### 14.60

```sql
create table bklyn_bgs as
select
    *
from
    nyc_2021_census_block_groups
where
    left(right(geoid, 10), 3) = '047'
```

### 14.61

```sql
create table brklyn_bgs_skater as
select
    *,
    st_geomfromtext(geometry) as geom
from
    pysal_skater('bklyn_bgs', 'geom', 'population', 'geoid', 8, 250)
```