require 'erb'

module Chartspec
  class Printer
    include ERB::Util
    
    def initialize(output)
      @output = output
    end
    
    def print_html_start
      chartspec_header = ERB.new File.new(File.expand_path("../../../templates/chartspec_header.html.erb", __FILE__)).read
      @output.puts chartspec_header.result(binding)
    end
    
    def flush
      @output.flush
    end
    
    def print_html_end
      chartspec_footer = ERB.new File.new(File.expand_path("../../../templates/chartspec_footer.html.erb", __FILE__)).read
      @output.puts chartspec_footer.result(binding)
    end
    
    private

  end
end