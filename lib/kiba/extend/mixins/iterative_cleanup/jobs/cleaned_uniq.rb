# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        module Jobs
          module CleanedUniq
            module_function

            def job(mod:)
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: mod.base_job_cleaned_job_key,
                  destination: mod.cleaned_uniq_job_key,
                  lookup: get_lookups(mod)
                },
                transformer: get_xforms(mod)
              )
            end

            def get_lookups(mod)
              base = [mod.base_job_cleaned_job_key]
              base.select { |job| Kiba::Extend::Job.output?(job) }
            end

            def get_xforms(mod)
              base = []
              if mod.respond_to?(:cleaned_uniq_pre_xforms)
                base << mod.cleaned_uniq_pre_xforms
              end

              base << if mod.cleanup_done?
                cleaned_xforms(mod)
              else
                orig_xforms(mod)
              end

              if mod.respond_to?(:cleaned_uniq_post_xforms)
                base << mod.cleaned_uniq_post_xforms
              end
              base
            end

            def orig_xforms(mod)
              bind = binding

              Kiba.job_segment do
                transform Rename::Fields,
                  fieldmap: bind.receiver.send(:fieldmap, mod)
                    .invert
                    .reject { |key, val| key == val }
              end
            end

            def cleaned_xforms(mod)
              bind = binding

              Kiba.job_segment do
                job = bind.receiver

                transform Deduplicate::Table,
                  field: mod.cleaned_values_identifier,
                  delete_field: false
                transform Delete::Fields,
                  fields: mod.cleaned_uniq_collate_fields
                transform Merge::MultiRowLookup,
                  lookup: send(mod.base_job_cleaned_job_key),
                  keycolumn: mod.cleaned_values_identifier,
                  fieldmap: job.send(:fieldmap, mod),
                  delim: mod.collation_delim
              end
            end

            def fieldmap(mod)
              mod.cleaned_uniq_collate_fields.map do |field|
                field_mapping(field)
              end.to_h
            end

            def field_mapping(field)
              if field.to_s.end_with?("s")
                [field, field]
              else
                ["#{field}s".to_sym, field]
              end
            end
            private :field_mapping
          end
        end
      end
    end
  end
end
