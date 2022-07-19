# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # @deprecated in 2.9.0. Use {Delete::DelimiterOnlyFieldValues} instead
        class DelimiterOnlyFields
          def initialize(delim:, use_nullvalue: false)
            
            nullval = use_nullvalue ? Kiba::Extend.nullvalue : nil
            @replacement = Delete::DelimiterOnlyFieldValues.new(
              fields: :all,
              delim: delim,
              treat_as_null: nullval
            )
            msg = 'Clean::DelimiterOnlyFields to be deprecated in a future release. Convert any usage of this transform to Delete::DelimiterOnlyFieldValues'
            warn("#{Kiba::Extend.warning_label}: #{msg}")
          end

          # @private
          def process(row)
            replacement.process(row)
          end

          private

          attr_reader :replacement
        end
      end
    end
  end
end
