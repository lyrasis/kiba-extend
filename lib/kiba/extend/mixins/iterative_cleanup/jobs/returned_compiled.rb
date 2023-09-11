# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        module Jobs
          module ReturnedCompiled
            module_function

            def job(mod:)
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: mod.returned_file_jobs,
                  destination: mod.returned_compiled_job_key
                },
                transformer: get_xforms(mod)
              )
            end

            def get_xforms(mod)
              base = []
              if mod.respond_to?(:returned_compiled_pre_xforms)
                base << mod.returned_compiled_pre_xforms
              end

              base << xforms(mod)

              if mod.respond_to?(:returned_compiled_post_xforms)
                base << mod.returned_compiled_post_xforms
              end
              base
            end

            def xforms(mod)
              Kiba.job_segment do
                transform Delete::Fields,
                  fields: :to_review
                transform Fingerprint::FlagChanged,
                  fingerprint: :clean_fingerprint,
                  source_fields: mod.fingerprint_fields,
                  delete_fp: true,
                  target: :corrected
                transform Delete::FieldnamesStartingWith,
                  prefix: "fp_"
                transform Clean::EnsureConsistentFields
              end
            end
          end
        end
      end
    end
  end
end
