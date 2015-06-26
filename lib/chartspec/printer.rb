require 'erb'

module Chartspec
  class Printer
    include ERB::Util
    
    def initialize(output)
      @output = output
      @assets_path = File.expand_path("../../../vendor/assets", __FILE__)
    end
    
    def print_html_start
      @title = ENV['CHARTSPEC_TITLE'] || 'Chartspec'
      chartspec_header = ERB.new File.new(File.expand_path("../../../templates/chartspec.html.erb", __FILE__)).read
      @output.puts chartspec_header.result(binding)
    end
    
    def flush
      @output.flush
    end
    
    def print_html_end
      @output.puts "</div></body></html>"
    end
    
    def print_group_start(group_id, chart, title, parents_count)
      @output.puts "<ul id='group_#{group_id}' class='media-list'><li class='media'>"
      parents_count.times do 
        @output.puts "<span class='media-left'>&nbsp;</span>"
      end
      @output.puts "<div class='media-body' style='width:100%;padding-bottom: 15px;'><h4 class='media-heading'>#{title}</h4>"
      @output.puts "<div class='thumbnail hide'><div id='chart_#{group_id}' data-chart='#{chart}' style='height:100px; width:100%;'></div></div>"
    end
    
    def print_group_end
      @output.puts "</div></li></ul>"
    end
    
    def print_example_passed(description, run_time, turnip = nil, video_path = nil)
      formatted_run_time = "%.5f" % run_time
      @output.puts "<div><div class='pull-right'>#{formatted_run_time}s</div><div class='text-success' style='border-bottom: 1px dotted #cccccc;'>&check; <b class='text-success'>"
      if (video_path)
        @output.puts " <button onclick=\"set_video('#{video_path}', '#{h(description)}'); $('#video').show().addClass('in')\" type='button' class='btn btn-warning btn-xs'>&#9658;</button>"
      end
      if turnip
        @output.puts "<table class='table table-condensed'>"
        turnip[:steps].each do |step|
          @output.puts "<tr class='success'><th>#{h step.keyword}#{h step.description}<th></tr>"
        end
        @output.puts "</table>"
      else
        @output.puts h(description)
      end
      @output.puts "</b></div></div>"
    end
    
    def print_example_failed(example_id, filepath, description, run_time, error, backtrace, turnip = nil, video_file = nil)
      formatted_run_time = "%.5f" % run_time
      @output.puts "<div><div class='pull-right'>#{formatted_run_time}s</div><div class='bg-danger' style='border-bottom: 1px dotted #cccccc;'>&nbsp;!&nbsp; <b class='text-danger'>"
      if (video_path)
        @output.puts " <button onclick=\"set_video('#{video_path}', '#{h(description)}'); $('#video').show().addClass('in')\" type='button' class='btn btn-warning btn-xs'>&#9658;</button>"
      end
      if turnip
        line = backtrace.find do |bt|
          bt.match(/#{filepath}:(\d+)/)
        end
        @failed_line_number = Regexp.last_match[1].to_i if line
        
        @output.puts "<table class='table table-condensed'>"
        turnip[:steps].each do |step|
          style = case
          when step.line == @failed_line_number then 'danger'
          when step.line < (@failed_line_number || 0) then 'success'
          else 'text-muted'
          end
          @output.puts "<tr class='#{style}'><th>#{h step.keyword}#{h step.description}</th></tr>"
        end
        @output.puts "</table>"
      else
        @output.puts h(description)
      end
      @output.puts "</b></div><blockquote class='small'><div class='text-danger'>#{error}</div><a href='#backtrace_#{example_id}' class='show_backtrace'>Show backtrace</a><small id='backtrace_#{example_id}' class='hide'>"
        backtrace.each do |btl|
          @output.puts "#{h btl}<br />"
        end
      @output.puts "</small></blockquote>"
    end
    
    def print_example_pending(description, pending_message, turnip = nil)
      @output.puts "<div><div class='pull-right'>(PENDING: #{h(pending_message)})</div><div class='bg-warning' style='border-bottom: 1px dotted #cccccc;'> &nbsp;*&nbsp; <b class='text-warning'>"
      if turnip
        @output.puts "<table class='table table-condensed'>"
        turnip[:steps].each do |step|
          @output.puts "<tr class='warning'><th>#{h step.keyword}#{h step.description}</th></tr>"
        end
        @output.puts "</table>"
      else
        @output.puts h(description)
      end
      @output.puts "</b></div></div>"
    end
    
    def print_chart_script file, chart, data = {}
      @output.puts "<script>draw_chart('#{chart}', #{data.values.to_json}, #{data.keys.to_json});</script>"
    end
  end
end