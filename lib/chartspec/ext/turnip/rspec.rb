# -*- coding: utf-8 -*-

require 'turnip/rspec'

module Turnip
  module RSpec
    class << self
      alias_method :super_run, :run

      def run(feature_file)
        features = super_run(feature_file)
        example_groups = ::RSpec.world.example_groups[-features.length..-1]

        features.zip(example_groups).each do |feature, example_group|
          add_steps_to_metadata(feature, example_group)
        end
        features
      end

      #
      # @param  [Turnip::Builder::Feature]   feature
      # @param  [RSpec::Core::ExampleGroup]  example_group
      #
      def add_steps_to_metadata(feature, example_group)
        background_steps = feature.backgrounds.map(&:steps).flatten
        examples = example_group.children

        feature.scenarios.zip(examples).each do |scenario, parent_example|
          example = parent_example.examples.first
          steps   = background_steps + scenario.steps
          tags    = (feature.tags + scenario.tags).uniq

          example.metadata[:chartspec_turnip] = { steps: steps, tags: tags }
        end
      end
    end
  end
end
