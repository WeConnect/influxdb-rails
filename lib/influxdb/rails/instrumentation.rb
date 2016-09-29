module InfluxDB
  module Rails
    module Instrumentation
      def benchmark_for_instrumentation
        start = Time.now
        yield

        unless InfluxDB::Rails.configuration.ignore_current_environment?
          elapsed = ((Time.now - start) * 1000).ceil
          InfluxDB::Rails.client.write_point "instrumentation", {
            values: {
              value: elapsed,
            },
            tags: {
              method: "#{controller_name}##{action_name}",
              host: Socket.gethostname,
              dyno: ENV["DYNO"]
            },
          }
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def instrument(methods = [])
          methods = [methods] unless methods.is_a?(Array)
          around_filter :benchmark_for_instrumentation, :only => methods
        end
      end
    end
  end
end
