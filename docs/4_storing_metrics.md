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

The image takes the __PRE_CREATE_DB__ environment variable and creates a database with that name, provided one doesn't exist already. InfluxDB runs an administrative web UI on port 8083, and uses port 8086 for the API to send metrics to. We only need to expose the API, as we can use that endpoint for both sending the data to, as well as for verifying the setup works.

# Configuring LogStash
Previously, we had LogStash pipe the output to the standard output. This is sufficient for debugging purposes, but now we're going to do some actual work. For this we'll need to install an output plugin and configure it so it will send the metrics through in a structured way. To do this, we add a few lines to the Dockerfile to install the plugin, and add the output configuration to the configuration file.

https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-event-structure.html

```Dockerfile
FROM logstash:2

RUN logstash-plugin install logstash-output-influxdb

COPY logstash.conf /etc/logstash/

CMD ["-f", "/etc/logstash/logstash.conf"]

```
The `RUN` line installs the InfluxDB output into our image. The rest is all in the logstash.conf file:

```ruby
input {
    beats {
        port => 5044
    }
}

output {
    influxdb {
        data_points => {
            "cpu.user.pct" => "%{[system][cpu][user][pct]}"
        }
        db => "metrics"
        host => "influxdb"
        retention_policy => ""
    }
}
```

The output block configures the newly installed InfluxDB output plugin to send metrics to our pre-created database. It can discover the InfluxDB endpoint based on the DNS resolution built into Docker. For the purpose of verifying that everything works, we'll ship only one data point into the data store.

# Verifying that it works

Everything should now be set up, so (cpu) metrics should be piped through LogStash into InfluxDB. To verify this, we can use some simple PowerShell to query the API for our new metrics:

```powershell
$query = [System.Web.HttpUtility]::UrlEncode("SELECT * FROM logstash")
$db = "metrics"
$data = Invoke-RestMethod "http://192.168.99.100:8086/query?db=$db&q=$query"
$data.results.series.values
```

This should show the recorded metrics. Something like this:

```
2016-12-05T13:12:37.556Z
0.0308
2016-12-05T13:12:38.553Z
0.0279
2016-12-05T13:12:39.554Z
0.0115
2016-12-05T13:12:40.554Z
0.0351
```

# Data retention policies
The metrics we store in InfluxDB have different use cases. The most recent measurements can be used to get a real-time overview of the services we monitor. For this purpose, it's important that the resolution of the measurements is high enough to get an accurate view of the current state. After some time however, these very granular measurements start to lose their value bit by bit. Over longer periods of time it's more interesting to look at the trends and patterns in the data.

One of the advantages of using a data store which is specifically designed for dealing with metrics ('time series') is that most of them come with [built-in support to deal with this exact issue](https://docs.influxdata.com/influxdb/v1.1/guides/downsampling_and_retention/). So let's configure a data retention policy for our metrics DB, and configure LogStash to use this policy for the metrics.

First, we'll need to create a new data retention policy. InfluxDB uses an SQL-like DSL over HTTP for interacting with the service. This DSL can be used to query the data store as well as modify the schemas and in this case, retention policies in particular.
Each InfluxDB database has one default and an arbitrary number of named retention policies. The syntax for this in InfluxDB-SQL is:
```SQL
CREATE RETENTION POLICY <retention_policy_name> ON <database_name> DURATION <duration> REPLICATION <n> [SHARD DURATION <duration>] [DEFAULT]
```

We'll create one on the _metrics_ database, with a duration of 1 hour (which is the minimum). We won't mess with defaults or sharding. The _REPLICATION_ clause determines how many independent copies of each point are stored in a cluster, which is irrelevant at the moment as we only have one node.

So putting this all together, we get this:
```SQL
CREATE RETENTION POLICY an_hour ON metrics DURATION 1h REPLICATION 1
```

In the logstash.conf file, we have to refer to this retention policy in the output section:

```ruby
...
output {
    influxdb {
        data_points => {
            "cpu.user.pct" => "%{[system][cpu][user][pct]}"
        }
        db => "metrics"
        host => "influxdb"
        retention_policy => "an_hour"
    }
}
...
```

That's all! Metrics will now be kept for no longer than one hour. 

# Next steps
Now that collecting and storing data is covered, it's time to do something with this data.
