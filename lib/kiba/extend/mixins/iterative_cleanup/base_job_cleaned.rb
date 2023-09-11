# frozen_string_literal: true

module Kiba::Extend::Mixins::IterativeCleanup::BaseJobCleaned
  module_function

  def job(mod:)
    Kiba::Extend::Jobs::Job.new(
      files: {
        source: mod.base_job,
        destination: mod.base_job_cleaned_job_key,
        lookup: get_lookups(mod)
      },
      transformer: get_xforms(mod)
    )
  end

  def get_lookups(mod)
    base = []
    base << mod.corrections_job_key if mod.cleanup_done?
    base.select { |job| Kiba::Extend::Job.output?(job) }
  end

  def get_xforms(mod)
    base = []
    if mod.respond_to?(:base_job_cleaned_pre_xforms)
      base << mod.base_job_cleaned_pre_xforms
    end
    base << xforms(mod)
    if mod.respond_to?(:base_job_cleaned_post_xforms)
      base << mod.base_job_cleaned_post_xforms
    end
    base
  end

  def xforms(mod)
    bind = binding

    Kiba.job_segment do
      job = bind.receiver
      lookups = job.send(:get_lookups, mod)

      transform Append::NilFields,
        fields: mod.worksheet_add_fields

      # Add :fingerprint (orig values) before merging any cleanup in
      transform Fingerprint::Add,
        target: :fingerprint,
        fields: mod.fingerprint_fields

      if mod.cleanup_done? && lookups.any?(mod.corrections_job_key)
        transform Fingerprint::MergeCorrected,
          lookup: method(mod.corrections_job_key).call,
          keycolumn: mod.orig_values_identifier,
          todofield: :corrected
      end

      transform Fingerprint::Add,
        target: :clean_fingerprint,
        fields: mod.fingerprint_fields
    end
  end
end
