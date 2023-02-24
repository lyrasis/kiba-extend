# frozen_string_literal: true

module Kiba
  module Extend
    # Base for kiba-extend specific errors, adding better identification of the
    #   job from which the error is being raised
    class Error < StandardError
      def calling_job
        pre_base_job_initialize.reject{ |loc| loc.path['kiba-extend'] }.first
      end

      private

      # returns caller_locations stack prior to initialization of kiba-extend
      #   BaseJob initialization
      def pre_base_job_initialize
        locs = caller_locations
        at_base_init = false
        until at_base_init
          loc = locs.shift
          at_base_init = true if loc.path.end_with?('base_job.rb') &&
            loc.label == 'initialize'
        end
        locs
      end
    end

    class InvalidActionError < ArgumentError
      include Kiba::Extend::ErrMod
      def initialize(msg="Action must be :keep or :reject")
        super
      end
    end

  end
end
