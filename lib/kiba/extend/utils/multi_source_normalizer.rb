# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # rubocop:todo Layout/LineLength
      # Helper to make it less tedious to ensure the same fields are present in all rows
      # rubocop:enable Layout/LineLength
      # rubocop:todo Layout/LineLength
      #   included in a multi-source job. This is annoying to deal with when the source tables have
      # rubocop:enable Layout/LineLength
      # rubocop:todo Layout/LineLength
      #   different fields. It's impossible to deal with without a helper if you are doing any
      # rubocop:enable Layout/LineLength
      #   of your jobs/transformations dynamically.
      #
      # The basic idea is:
      # rubocop:todo Layout/LineLength
      # - an new instance of this class is created somewhere accessible from within jobs. In Kiba::TMS
      # rubocop:enable Layout/LineLength
      # rubocop:todo Layout/LineLength
      #   this is a config settig per multi-source job: `Kiba::Tms.config.name_compilation.multi_source_normalizer`
      # rubocop:enable Layout/LineLength
      #
      # rubocop:todo Layout/LineLength
      # - pass this instance in as a helper on the `MultiSourcePrepJob`s that generate files that will be used
      # rubocop:enable Layout/LineLength
      #   as sources in the multisource job:
      #
      # ```
      #  Kiba::Extend::Jobs::MultiSourcePrepJob.new(
      #   files: {
      #     source: :prep__obj_locations,
      #     destination: :names__from_obj_locations
      #   },
      #   transformer: from_obj_locations_xforms,
      #   helper: Kiba::Tms.config.name_compilation.multi_source_normalizer
      # )
      # ```
      #
      # rubocop:todo Layout/LineLength
      # Finally, in the multisource job, call the `get_fields` method of your normalizer as the `fields`
      # rubocop:enable Layout/LineLength
      #   argument of an `Append::NilFields` transform:
      #
      # ```
      # rubocop:todo Layout/LineLength
      # transform Append::NilFields, fields: Tms.config.name_compilation.multi_source_normalizer.get_fields
      # rubocop:enable Layout/LineLength
      # ```
      # rubocop:todo Layout/LineLength
      # @note This currently only works when using `Kiba::Extend::Destinations::CSV` destination. It depends on
      # rubocop:enable Layout/LineLength
      # rubocop:todo Layout/LineLength
      #   the `fields` method added to that class to support. This was not added to the
      # rubocop:enable Layout/LineLength
      # rubocop:todo Layout/LineLength
      #   `Kiba::Extend::Destinations::JsonArray` class because it does not require an identical field set
      # rubocop:enable Layout/LineLength
      #   in all records
      # @since 2.7.0
      class MultiSourceNormalizer
        def initialize
          @fields = []
        end

        # @return [Array<Symbol>]
        def get_fields
          fields.flatten.uniq.sort
        end

        # @param new_fields [Array<Symbol>]
        def record_fields(new_fields)
          fields << new_fields
        end

        private

        attr_reader :fields
      end
    end
  end
end
