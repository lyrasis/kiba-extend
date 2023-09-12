# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        module Jobs
          module Worksheet
            module_function

            def job(mod:)
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: mod.cleaned_uniq_job_key,
                  destination: mod.worksheet_job_key
                },
                transformer: get_xforms(mod)
              )
            end

            def get_xforms(mod)
              base = []
              if mod.respond_to?(:worksheet_pre_xforms)
                base << mod.worksheet_pre_xforms
              end
              base << xforms(mod)
              if mod.respond_to?(:worksheet_post_xforms)
                base << mod.worksheet_post_xforms
              end
              base
            end

            def xforms(mod)
              Kiba.job_segment do
                unless mod.provided_worksheets.empty?
                  # rubocop:disable Layout/LineLength
                  known_vals =
                    Kiba::Extend::Mixins::IterativeCleanup::KnownWorksheetValues.new(
                      mod
                    ).call
                  # rubocop:enable Layout/LineLength
                  transform Append::NilFields,
                    fields: :to_review
                  transform do |row|
                    ids = row[mod.collated_orig_values_id_field]
                    next row if ids.blank?

                    known = ids.split(mod.collation_delim)
                      .map { |id| known_vals.include?(id) }
                      .all?
                    next row if known

                    row[:to_review] = "y"
                    row
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
