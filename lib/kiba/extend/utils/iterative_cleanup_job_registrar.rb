# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Adds jobs defined by {Kiba::Extend::Mixins::IterativeCleanup} to
      #   registry
      #
      # @since 4.0.0
      class IterativeCleanupJobRegistrar
        def self.call
          new.call
        end

        def initialize
          @to_register = gather
        end

        def call
          puts "Registering iterative cleanup jobs"
          to_register.each do |mod|
            mod.register_cleanup_jobs
          end
        end

        private

        attr_reader :to_register

        def gather
          Kiba::Extend.project_configs.select do |config|
            config.is_a?(Kiba::Extend::Mixins::IterativeCleanup)
          end
            .group_by { |c| c.to_s.split("::").last }
            .values
            .map { |arr| arr.last }
            .flatten
        end
      end
    end
  end
end
