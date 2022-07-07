# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations that do some sort of data deduplication
      #
      # ## Choosing between similar transforms
      #
      # - {{Deduplicate::Flag}} - Keeps all rows. The first row with a duplicate value is **not** marked as
      #   a duplicate. Subsequent rows with the same value are marked as duplicates. Use to non-destructively
      #   identify what will be kept/lost in a deduplication process, so you set up subsequent jobs to
      #   (a) report dropped non-unique rows; and (b) process the unique (non-duplicate) rows. Works one row
      #   at a time, so there is no performance implication due to source size.
      # - {{Deduplicate::FlagAll}} - Keeps all rows. All rows with a duplicate value are marked as duplicates.
      #   This is most helpful if you are wanting to review all duplicate values in a result together, or if
      #   you need to, in a subsequent step, filter out all values that are not unique. Holds all rows in
      #   memory while processing, so may be slow or even fail with very large source data.
      # - {{Deduplicate::Table}} - Destructive! Removes rows. Keeps only the first row of any rows with the same
      #   value in the specified field. Holds all rows in memory while processing, so may be slow or even fail
      #   with very large source data. Equivalent to running {{Deduplicate::Flag}} followed by
      #   {{FilterRows::FieldEqualTo}} (to reject duplicate rows), which should be used if size of source data
      #   is a problem.
      module Deduplicate
        ::Deduplicate = Kiba::Extend::Transforms::Deduplicate
      end
    end
  end
end
