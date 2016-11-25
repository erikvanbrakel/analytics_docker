FROM logstash:2

RUN logstash-plugin install logstash-output-riemann

COPY logstash.conf /etc/logstash/

CMD ["-f", "/etc/logstash/logstash.conf"]
