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