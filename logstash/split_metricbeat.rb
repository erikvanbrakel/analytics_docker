# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::SplitMetricbeat < LogStash::Filters::Base
  config_name "split_metricbeat"
  milestone 1

  public
  def register
  end

  def flatten(event)
    event.each_with_object({}) do |(k, v), h|
      if v.is_a? Hash
        flatten(v).map do |h_k, h_v|
          h["#{k}.#{h_k}"] = h_v
        end
      else
        h[k] = v
      end
    end
  end

  public
  def filter(event)
    return unless filter?(event)
    hash = flatten(event.to_hash)
    hash.each do |k,v|
      next unless v.is_a? Numeric
      e = LogStash::Event.new(
        "type" => "metric",
        "@timestamp" => event["@timestamp"],
        "service" => "#{event["beat"]["hostname"]} #{k}",
        "metric" => v,
        "@metadata" => {
          "type" => "metric"
        }
      )
      yield e
    end
    event.cancel
  end
end
