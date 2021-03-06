# Collecting data
Obviously, the most important part of any monitoring and analytics system is the data. Without it, there's nothing to analyze which renders
the system useless. For this, we introduce [LogStash](https://www.elastic.co/products/logstash) to the stack. From their website:

> Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”

For collecting system metrics we'll use the [Beats platform](https://www.elastic.co/products/beats), mainly because it runs on both Linux and Windows out of
the box. Later on we'll investigate more options for this.

# Configuring LogStash
Luckily, there's an official LogStash docker image available in the Docker Hub (https://hub.docker.com/_/logstash/). One thing to note is that
because the latest version (5) is quite new, other systems don't integrate that well with it yet. So we'll start with a container based on the
previous version (2). 

Additionally, LogStash needs some basic configuration to actually do something. We have to tell it how it can accept data, and in turn where it
should forward that. The listing below shows that:

```ruby
input {
    beats {
        port => 5044
    }
}

output {
    stdout { codec => 'rubydebug' }
}
```
_(./logstash/logstash.conf)_

The `input` block tells LogStash that it should accept metrics using the Beats protocol, on port 5044 (the default port for Beats). The `output`
block tells it to print everything to the standard output stream. The codec makes sure that it's (sort of) human readable, for debugging purposes.

Later on, this configuration will get a little bit more elaborate, but for now this is good enough to verify that we can enter data into the system.

# Building the image
For the LogStash container image, we'll use the publicly available image from the Docker Hub, with a few minor customisations. 

```Dockerfile
FROM logstash:2

COPY logstash.conf /etc/logstash/

CMD ["-f", "/etc/logstash/logstash.conf"]
```
_(./logstash/Dockerfile)_

This will build a container based on logstash version 2.x, copy the configuration file to `/etc/logstash` and run LogStash pointing to that directory.

# First run
So let's see how we can start bringing the stack to life. For this, we'll use [Docker Compose](https://docs.docker.com/compose/). Docker Compose
uses a simple YAML based configuration file, which defines, among other things, which containers to run, how they relate to eachother,
and what those containers expose to the outside world. For now, we just need to make sure our LogStash container exposes port 5044, so MetricBeat
can start sending data to it.

```YAML
version: '2'
services:
  logstash:
    build: logstash/
    ports:
      - "5044:5044"
```
_(./docker-compose.yml)_

To run this setup, simply run `docker-compose up` in the root of the project. This will build the LogStash image and run a container based on that
image.

# Verifying that it works
As said before, we'll use (MetricBeat)[https://www.elastic.co/downloads/beats/metricbeat] initially to easily ship system metrics into the monitoring system. After installing it, we need to configure it slightly to enable shipping to LogStash. The default configuration ships a couple of metrics to ElasticSearch, but we don't want that.

```YAML
metricbeat.modules:
- module: system
  metricsets:
    - cpu
  enabled: true
  period: 1s

output.logstash:
  hosts: ["your_docker_machine_ip_here:5044"]
```
_(./metricbeat.yml)_

This will push cpu metrics to LogStash at a 1 second interval. You will have to point metricbeat to the IP address of your docker machine, which you can find by using the `docker-machine` command line and some PowerShell:

```powershell
$machine_info = docker-machine inspect | ConvertFrom-Json
$machine_info.Driver.IPAddress
```

When you start the stack using `docker-compose up` you should see the following output:
```
logstash_1  | log4j:WARN No appenders could be found for logger (io.netty.util.internal.logging.InternalLoggerFactory).
logstash_1  | log4j:WARN Please initialize the log4j system properly.
logstash_1  | log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
```

You can safely ignore this warning for now, as we're just testing. When you start Metricbeat you will see the metric sets coming through.

# Next steps
With LogStash up and running, data collection is sorted. The next step is storing these metrics somewhere so we can work with them.
