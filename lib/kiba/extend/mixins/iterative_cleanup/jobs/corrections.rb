# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        module Jobs
          module Corrections
            module_function

            def job(mod:)
              return unless mod.cleanup_done?

              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: mod.returned_compiled_job_key,
                  destination: mod.corrections_job_key
                },
                transformer: get_xforms(mod)
              )
            end

            def get_xforms(mod)
              base = []
              if mod.respond_to?(:corrections_pre_xforms)
                base << mod.corrections_pre_xforms
              end

              base << xforms(mod)

              if mod.respond_to?(:corrections_post_xforms)
                base << mod.corrections_post_xforms
              end
              base
            end

            def xforms(mod)
              Kiba.job_segment do
                transform FilterRows::FieldPopulated,
                  action: :keep,
                  field: :corrected
                transform Explode::RowsFromMultivalField,
                  field: mod.collated_orig_values_id_field,
                  delim: mod.collation_delim
                transform Rename::Field,
                  from: mod.collated_orig_values_id_field,
                  to: mod.orig_values_identifier
                transform CombineValues::FullRecord
                transform Deduplicate::Table,
                  field: :index,
                  delete_field: true
              end
            end
          end
        end
      end
    end
  end
end
