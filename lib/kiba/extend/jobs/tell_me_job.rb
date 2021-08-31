# frozen_string_literal: true

require 'kiba/extend'
module Kiba
  module Extend
    module Jobs
      # Mixin to activate having computer say (out loud!) that the job is complete
      #
      # Useful for long-running jobs
      module TellMeJob
        def decorate
          context.instance_variable_set(:@job_key, job_data.key.to_s.delete('_'))
          parse_job(control, context, [tell])
        end

        def tell
          Kiba.job_segment do
            post_process do
              `say #{@job_key} job is complete`
            end
          end
        end
      end
    end
  end
end
