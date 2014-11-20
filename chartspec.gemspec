# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chartspec/version'

Gem::Specification.new do |spec|
  spec.name          = "chartspec"
  spec.version       = Chartspec::VERSION
  spec.authors       = ["AlexVangelov"]
  spec.email         = ["email@data.bg"]
  spec.summary       = %q{RSpec with execution time history charts}
  spec.description   = %q{Generates HTML files with case execution time charts for recurrent RSpec tests}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency 'rspec'
  spec.add_dependency 'sqlite3'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.executables << 'chartspec'
end
