# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        module Jobs
          module Final
            module_function

            def job(mod:)
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: mod.base_job_cleaned_job_key,
                  destination: mod.final_job_key
                },
                transformer: get_xforms(mod)
              )
            end

            def get_xforms(mod)
              base = []
              if mod.respond_to?(:final_pre_xforms)
                base << mod.final_pre_xforms
              end
              base << xforms(mod)
              if mod.respond_to?(:final_post_xforms)
                base << mod.final_post_xforms
              end
              base
            end

            def xforms(mod)
              Kiba.job_segment do
                # passthrough - pre and post mean nothing here
              end
            end
          end
        end
      end
    end
  end
end
