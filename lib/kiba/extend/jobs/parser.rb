# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      module Parser
        def parse_job(control, context, *job_segments)
          job_segments = job_segments.flatten
          job_segments.each { |segment|
            context.instance_eval(&segment)
          }
          control
        end
      end
    end
  end
end
