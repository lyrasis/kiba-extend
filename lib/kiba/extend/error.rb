# frozen_string_literal: true

module Kiba
  module Extend
    module ErrMod
      def calling_job
        pre_base_job_initialize.reject { |loc| loc.path["kiba-extend"] }.first
      end

      def info
        puts "#{self.class.name}: #{message}"
        puts "AT:"
        puts backtrace.first(10)
      end

      private

      # returns caller_locations stack prior to initialization of kiba-extend
      #   BaseJob initialization
      def pre_base_job_initialize
        locs = caller_locations
        at_base_init = false
        until at_base_init
          loc = locs.shift
          at_base_init = true if loc.path.end_with?("base_job.rb") &&
            loc.label == "initialize"
        end
        locs
      end
    end

    class BooleanReturningLambdaError < TypeError
      include Kiba::Extend::ErrMod
      def initialize(msg = "Lambda must return true or false")
        super
      end
    end

    class InvalidActionError < ArgumentError
      include Kiba::Extend::ErrMod
      def initialize(msg = "Action must be :keep or :reject")
        super
      end
    end

    class IterativeCleanupSettingUndefinedError < StandardError
      include Kiba::Extend::ErrMod
    end

    class ProjectSettingUndefinedError < StandardError
      include Kiba::Extend::ErrMod
    end

    class PathRequiredError < ArgumentError
      include Kiba::Extend::ErrMod
      def initialize(klass)
        super("Provide path for #{klass}")
      end
    end

    # Base for kiba-extend specific errors, adding better identification of the
    #   job from which the error is being raised
    class Error < StandardError
      include Kiba::Extend::ErrMod
    end
  end
end
