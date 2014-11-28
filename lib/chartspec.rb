require "chartspec/version"
require "chartspec/formatter"
if Gem::Specification::find_all_by_name('turnip').any?
  require "chartspec/ext/turnip/rspec"
end
