# 13 - Routing and networks with pgRouting

## 13.1 Prepare data to use in pgRouting

### 13.1

```sh
docker run --name mini-postgis -p 35432:5432 --network="host" 
-v /Users/mattforrest/Desktop/Desktop/spatial-sql-book/raster:/mnt/mydata 
-e POSTGRES_USER=admin -e POSTGRES_PASSWORD=password -d postgis/postgis:15-master
```

### 13.2

```sh
docker container exec -it mini-postgis bash
```

### 13.3

```sh
apt update
apt install osm2pgrouting
```

### 13.4

```sh
apt install osmctools
```

### 13.5

```sh
osmfilter /mnt/mydata/planet_-74.459,40.488_-73.385,41.055.osm --keep="highway=" \
-o=/mnt/mydata/good_ways.osm
```







