require "chartspec/version"
require "rspec"
require "rspec/core/formatters/progress_formatter"
require "rspec/core/formatters/console_codes"
require 'sqlite3'
require 'erb'

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
    RSpec::Core::Formatters.register self, :start, :stop, :example_group_started, :start_dump, :example_started, :example_passed, :example_failed, :example_pending, :dump_profile
    
    def initialize(output)
      super(output)
      @db = SQLite3::Database.new( ENV["CHARTSPEC_DB"] || "tmp/chartspec.sqlite3" )
      @title = ENV["CHARTSPEC_TITLE"]
      @name = ENV["CHARTSPEC_NAME"]
      @db.execute( "CREATE TABLE IF NOT EXISTS specs(id INTEGER PRIMARY KEY, file TEXT, name TEXT, duration NUMERIC, measured_at DATETIME);" )
    end
    
    def start(notification)
      super
      @failed_examples = []
      @example_group_number = 0
      @example_number = 0
      @header_red = false
      @output_hash = {}
    end
    
    def stop(notification)
      @output_hash[:examples] = notification.examples.map do |example|
        format_example(example).tap do |hash|
          e = example.exception
          if e
            hash[:exception] =  {
              :class => e.class.name,
              :message => e.message,
              :backtrace => e.backtrace,
            }
          else
            @db.execute("INSERT INTO specs(file, name, duration, measured_at) VALUES (?, ?, ?, ?)", [
              example.metadata[:file_path], example.full_description, example.execution_result.run_time, Time.now.to_i
            ]) if example.metadata[:chart]
          end
        end
      end
    end
    
    def dump_summary(summary)
      output.puts summary.fully_formatted
      @output_hash[:summary] = {
        :duration => summary.duration,
        :example_count => summary.example_count,
        :failure_count => summary.failure_count,
        :pending_count => summary.pending_count
      }
      @output_hash[:summary_line] = summary.totals_line
      
      specs_history = [].tap do |cd|
        @db.execute( "select file, name, duration, measured_at from specs where measured_at > ?", (Time.now - ((ENV['CHARTSPEC_HISTORY_HOURS'] || 2)*3600)).to_i).each do |row|
          cd << {
            file: row[0],
            name: row[1], 
            duration: row[2], 
            measured_at: row[3]
          }
        end
      end
      
      @chart_data = {}.tap do |spec_summary|
        specs_history.group_by{ |x| x[:name] }.each do |name, specs|
          measures = []
          specs.each do |spec|
            measures << [Time.at(spec[:measured_at]), spec[:duration], spec[:name]]
          end
          spec_summary[name] = measures
        end
      end

      @chartspec_root = File.expand_path("../../", __FILE__)
      template = ERB.new File.new(File.expand_path("../../templates/chartspec.html.erb", __FILE__)).read, nil, "%"
      template.result(binding)

      File.open(ENV["CHARTSPEC_HTML"] || "tmp/chartspec.html", "w") do |file|
        file.puts template.result(binding)
      end
    end
    
    def example_group_started(notification)
      super
      @example_group_red = false
      @example_group_number += 1
    end

    def start_dump(_notification)
    end

    def example_started(_notification)
      @example_number += 1
    end

    def example_passed(passed)
      super
    end
    
    def example_failed(failure)
      super
      @failed_examples << failure.example
      unless @header_red
        @header_red = true
      end
    end
    
    def example_pending(pending)
      super
    end
    
    private
      def format_example(example)
        {
          :description => example.description,
          :full_description => example.full_description,
          :status => example.execution_result.status.to_s,
          :file_path => example.metadata[:file_path],
          :line_number  => example.metadata[:line_number],
          :run_time => example.execution_result.run_time
        }
      end
    
  end
end
