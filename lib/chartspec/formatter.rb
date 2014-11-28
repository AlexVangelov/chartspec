require "rspec"
require "rspec/core/formatters/base_text_formatter"
require "rspec/core/formatters/console_codes"
require "chartspec/printer"
require "chartspec/db"
require 'json'

module Chartspec
  class Formatter < RSpec::Core::Formatters::BaseTextFormatter
    RSpec::Core::Formatters.register self, :start, :example_group_started, :start_dump, :example_started, :example_passed, :example_failed, :example_pending, :dump_failures, :dump_pending
    
    def initialize(output)
      super output
      @failed_examples = []
      @current_file = {}
      @example_group_number = 0
      @example_number = 0
      @header_red = false
      @db = Db.new ENV["CHARTSPEC_DB"]
      @printer = Printer.new output
      @charts = {}
    end
    
    def start(notification)
      @printer.print_html_start
      @printer.flush
    end
    
    def dump_summary(summary)
      puts summary.totals_line
      @printer.print_html_end
      @printer.flush
    end
    
    def example_group_started(notification)
      @example_group_red = false
      @example_group_number += 1
      
      unless example_group_number == 1
        @printer.print_group_end
        generate_chart @current_file, @current_group
      end
      @printer.print_group_start example_group_number, notification.group.to_s, notification.group.description, notification.group.parent_groups.size
      @charts[@example_group_number] = []
    end
  
    def start_dump(notification)
      @printer.print_group_end
      generate_chart @current_file, @current_group
      puts
    end
  
    def example_started(notification)
      @example_number += 1
      @current_group = notification.example.example_group
      @current_file = notification.example.metadata[:file_path]
    end
  
    def example_passed(passed)
      putc RSpec::Core::Formatters::ConsoleCodes.wrap('.', :success)
      @printer.print_example_passed(passed.example.description, passed.example.execution_result.run_time, passed.example.metadata[:turnip])
      @db.add(
        passed.example.metadata[:file_path], 
        passed.example.example_group, 
        passed.example.description, 
        passed.example.execution_result.run_time
       ) if passed.example.metadata[:chart]
    end
    
    def example_failed(failure)
      putc RSpec::Core::Formatters::ConsoleCodes.wrap('F', :failure)
      @failed_examples << failure.example
      unless @header_red
        @header_red = true
      end
      @printer.print_example_failed(@example_number, failure.example.metadata[:file_path], failure.example.description, failure.example.execution_result.run_time,
        failure.example.exception.message, failure.example.exception.backtrace, failure.example.metadata[:turnip])
    end
    
    def example_pending(pending)
      putc RSpec::Core::Formatters::ConsoleCodes.wrap('*', :pending)
      @printer.print_example_pending(pending.example.description, pending.example.execution_result.pending_message, pending.example.metadata[:turnip])
    end
    
    def dump_failures(notification)
      return if notification.failure_notifications.empty?
      puts notification.fully_formatted_failed_examples
    end

    def dump_pending(notification)
      return if notification.pending_examples.empty?
      puts notification.fully_formatted_pending_examples
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
    
      def generate_chart example_file, example_group
        return unless example_group and example_file
        
        chart_data = {}.tap do |spec_summary|
          @db.select_by_file_and_chart(example_file, example_group).group_by{ |x| x[0] }.each do |name, specs|
            measures = []
            specs.each do |spec|
              measures << [Time.at(spec[2]), spec[1]]
            end
            spec_summary[name[0..60]] = measures
          end
        end
        @printer.print_chart_script(example_file, example_group, chart_data) unless chart_data.empty?
      end
  end
end