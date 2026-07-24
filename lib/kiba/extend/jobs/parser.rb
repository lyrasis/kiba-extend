# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      module Parser
        # Evals job_segment Procs defined for a job in the job context
        # @param control [Kiba::Control]
        # @param context [Kiba::Context]
        # @param job_segments [Array<Proc>]
        # @return [Kiba::Control]
        def parse_job(control, context, *job_segments)
          job_segments = job_segments.flatten
          job_segments.compact.each do |segment|
            context.instance_eval(&segment)
          end
          control
        end
      end
    end
  end
end
