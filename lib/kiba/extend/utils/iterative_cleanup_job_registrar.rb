# frozen_string_literal: true

module Kiba::Extend::Utils
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
    end
  end
end
