require "chartspec/version"
require "rspec"
require "rspec/core/formatters/progress_formatter"
require "rspec/core/formatters/console_codes"

module Chartspec
  def self.run argv
    config = RSpec.configuration
    formatter = Formatter.new config.output_stream
    reporter = RSpec::Core::Reporter.new(config)
    config.instance_variable_set :@reporter, reporter
    loader = config.send :formatter_loader
    notifications = loader.send :notifications_for, Formatter
    reporter.register_listener formatter, *notifications
    RSpec::Core::Runner::run [argv]
  end
  
  class Formatter < RSpec::Core::Formatters::ProgressFormatter
    RSpec::Core::Formatters.register self, :message, :dump_summary, :dump_profile, :stop, :close
    
    def initialize(output)
      super
      p "initialize"
    end
    
    def message(notification)
      p "message"
    end
    
    def dump_summary(summary)
      output.puts summary.fully_formatted
    end
    
    def stop(notification)
      p "stop"
      notification.examples.each do |example|
        p example.inspect  
      end
    end
    
    def close(notification)
      p "close"
      super
    end
    
    def dump_profile(profile)
      p "dump_profile"
    end
  end
end
