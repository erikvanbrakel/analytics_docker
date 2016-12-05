# Storing metrics
The metrics collected from our systems and services are what we time series. Time series are series of data points, indexed in time order. 
As is very much in fashion nowadays, we'll want to store these time series in a data store optimized for this purpose. For this purpose, we'll
use [InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/).

From their website:
> InfluxDB is an open source database written in Go specifically to handle time series data with high availability and high performance requirements. InfluxDB installs in minutes without external dependencies, yet is flexible and scalable enough for complex deployments.

# Configuring InfluxDB
As with LogStash, there is an official InfluxDB container image available in the Docker Hub (https://hub.docker.com/_/influxdb/). This will setup the InfluxDB service and expose the correct ports. However, to be able to send metrics to the data store we need to create a database as well. To do that, we would have to create a custom start-up script and build our own container image. To work around this requirement, we can use a different container image which is also available in the Docker Hub (https://hub.docker.com/r/tutum/influxdb/). This image adds the ability to pre-create a database, which makes setting up the stack a bit easier.

First, we need to add the service definition to the Dockerfile:

```Dockerfile
version: '2'
services:
  ...
  influxdb:
    image: tutum/influxdb
    environment:
      PRE_CREATE_DB: "metrics"
    ports:
      - "8083:8083"
    expose:
      - "8086"
    ...
```

The image takes the __PRE_CREATE_DB__ environment variable and creates a database with that name, provided one doesn't exist already. InfluxDB runs an administrative web UI on port 8083, and uses port 8086 for the API to send metrics to. We need to expose the API to the other containers, and the UI to the host system so we can take a look at it for inspection purposes.

# Configuring LogStash
|| TODO ||
