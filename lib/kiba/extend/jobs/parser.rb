
module Kiba
  module Extend
    module Jobs
      module Parser
        def parse_job(*job_segments)
          job_segments = job_segments.flatten
          control = Kiba::Control.new
          context = Kiba::Context.new(control)
          job_segments.each{ |segment|
            context.instance_eval(&segment)
          }
          control
        end
      end
    end
  end
end
