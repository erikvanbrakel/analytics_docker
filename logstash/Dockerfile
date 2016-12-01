FROM logstash:2

RUN logstash-plugin install logstash-output-riemann
RUN logstash-plugin install logstash-filter-prune

COPY logstash.conf /etc/logstash/
RUN mkdir -p /var/lib/logstash/filters
COPY split_metricbeat.rb /var/lib/logstash/filters/split_metricbeat.rb

CMD ["-f", "/etc/logstash/logstash.conf", "-p", "/var/lib"]
