require "rspec"
require "rspec/core/formatters/progress_formatter"
require "chartspec/printer"
require "chartspec/db"
require 'json'

module Chartspec
  class Formatter < RSpec::Core::Formatters::ProgressFormatter
    RSpec::Core::Formatters.register self, :start, :stop, :example_group_started, :start_dump, :example_started, :example_passed, :example_failed, :example_pending, :dump_profile
    
    def initialize(output)
      super output
      @failed_examples = []
      @current_file = {}
      @example_group_number = 0
      @example_number = 0
      @header_red = false
      @db = Db.new ENV["CHARTSPEC_DB"]
      #@printer = Printer.new output 
    end
    
    def start(notification)
      super
      @output_hash = {}
      #@printer.print_html_start
      #@printer.flush
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
            @db.add example.metadata[:file_path], example.full_description, example.execution_result.run_time
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
        @db.all.each do |row|
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
  
      @chartspec_root = File.expand_path("../../../", __FILE__)
      template = ERB.new File.new(File.expand_path("../../../templates/chartspec.html.erb", __FILE__)).read, nil, "%"
      template.result(binding)
  
      @chart_file = ENV["CHARTSPEC_HTML"] || "tmp/chartspec.html"
      chart_dirname = File.dirname(@chart_file)
      unless File.directory?(chart_dirname)
        FileUtils.mkdir_p(chart_dirname)
      end
      File.open(@chart_file, "w") do |file|
        file.puts template.result(binding)
      end
      puts "* Chartspec output: #{@chart_file}\n"
      puts "* Chartspec tmp_db: #{@db.file_name}\n"
    end
    
    def example_group_started(notification)
      super
      @example_group_red = false
      @example_group_number += 1
    end
  
    def start_dump(notification)

    end
  
    def example_started(notification)
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
      def example_group_number
        @example_group_number
      end
        
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