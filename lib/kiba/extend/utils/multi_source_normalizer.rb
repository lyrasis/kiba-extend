# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Helper to make it less tedious to ensure the same fields are present in all rows
      #   included in a multi-source job. This is annoying to deal with when the source tables have
      #   different fields. It's impossible to deal with without a helper if you are doing any
      #   of your jobs/transformations dynamically.
      #
      # The basic idea is:
      # - an new instance of this class is created somewhere accessible from within jobs. In Kiba::TMS
      #   this is a config settig per multi-source job: `Kiba::Tms.config.name_compilation.multi_source_normalizer`
      # 
      # - pass this instance in as a helper on the `MultiSourcePrepJob`s that generate files that will be used
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
      #```
      #
      # Finally, in the multisource job, call the `get_fields` method of your normalizer as the `fields`
      #   argument of an `Append::NilFields` transform:
      #
      # ```
      # transform Append::NilFields, fields: Tms.config.name_compilation.multi_source_normalizer.get_fields
      # ```
      # @note This currently only works when using `Kiba::Extend::Destinations::CSV` destination. It depends on
      #   the `fields` method added to that class to support
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
