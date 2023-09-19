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

    class JobCannotBeUsedAsLookupError < TypeError
      include Kiba::Extend::ErrMod
      def initialize(key, klass, for_job)
        @key = key
        @klass = klass
        @for_job = for_job
        @msg = ":#{key} cannot be used as a lookup in :#{for_job} because "\
          "its src_class (#{klass}) does not include "\
          "Kiba::Extend::Soures::Lookupable"
        super(msg)
      end

      def formatted
        <<~STR
          JOB FAILED: LOOKUP FILE SETUP ERROR FOR: #{for_job}
            #{msg}
        STR
      end

      private

      attr_reader :key, :klass, :for_job, :type, :msg
    end

    # Exception raised if {Kiba::Extend::FileRegistry} contains no lookup
    #   key for file
    class NoLookupOnError < NameError
      include Kiba::Extend::ErrMod
      # @param filekey [Symbol] key not found in
      #   {Kiba::Extend::FileRegistry}
      def initialize(filekey, for_job)
        @filekey = filekey
        @for_job = for_job
        msg = "No lookup_on value in registry entry hash for :#{filekey} -- "\
          "Used as lookup in job: :#{for_job})"
        super(msg)
      end

      def formatted
        <<~STR
          JOB FAILED: LOOKUP FILE SETUP ERROR FOR: #{for_job}
            To fix: Add `lookup_on` to registry entry hash for
              :#{filekey}
        STR
      end

      private

      attr_reader :filekey, :for_job
    end

    # Exception raised if the lookup key value for the file is not a Symbol
    class NonSymbolLookupOnError < TypeError
      include Kiba::Extend::ErrMod
      # @param filekey [Symbol] registry entry key having the non-symbol
      #   `lookup_on` value
      def initialize(filekey, for_job)
        @filekey = filekey
        @for_job = for_job
        @msg = "The `lookup_on` value in the registry entry hash for "\
          ":#{filekey} is not a Ruby Symbol. "\
          "Prepend a : to the field name to fix."
        super(msg)
      end

      def formatted
        <<~STR
          JOB FAILED: LOOKUP FILE SETUP ERROR FOR: #{for_job}
            #{msg}
        STR
      end

      private

      attr_reader :filekey, :for_job, :msg
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
