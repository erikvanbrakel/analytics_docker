# Docker logging & monitoring playground
Run an analytics stack loosely based on the examples from '[The Art of Monitoring](https://www.artofmonitoring.com/)', using docker containers.

# Summary
The stack includes:
 - [ElasticSearch](https://www.elastic.co/products/elasticsearch) for indexing structured log entries
 - [Logstash](https://www.elastic.co/products/logstash) for routing events (mainly because of beats)
 - [Riemann](http://riemann.io/) for stream processing
 - [InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/) for storing metrics
 - [Grafana](https://grafana.net/) for visualizations


# Requirements
## Setup

1. Install [Docker](http://docker.io) **tested with version >= 1.12.3**.
2. Install [Docker-compose](http://docs.docker.com/compose/install/) **tested with version >= 1.8.1**.
3. Clone this repository

## Increase max_map_count on your host (docker-machine)

To be able to run ElasticSearch, you need to increase `max_map_count` on your (boot2)Docker host:

From the docker CLI, connect to your docker VM: ```docker-machine ssh```
Open ```/var/lib/boot2docker/profile``` and add ```sysctl -w vm.max_map_count=262144```

# Usage
Start the ELK stack using *docker-compose*:

```bash
$ docker-compose up
```

You can also choose to run it in background (detached mode):

```bash
$ docker-compose up -d
```

Now that the stack is running, you'll want to inject logs in it. The shipped logstash configuration allows you to send content via beats. The easiest way to get something into the stack is to run metricbeat
on your host machine, and making the docker machine IP your endpoint. To find the IP of your docker machine, run ```docker-machine inspect``` from the commandline and find the IPAddress value.
 
# Credits
I've taken inspiration from:
 - https://github.com/deviantony/docker-elk
 - https://github.com/simonjohansson/crig
