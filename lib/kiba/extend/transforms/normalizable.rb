# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module for transform classes to add a @normalizer instance
      #  variable that sets up an instance of Utils::StringNormalizer
      #
      # ## Testing
      #
      # This mixin's funtionality is tested in Deduplicate::GroupedFieldValues
      #   and Deduplicate::FieldGroup. It is not imperative to test in in every
      #   additional transform class where it may be used.
      #
      # ## Usage
      #
      # In class definition:
      #
      # ~~~
      # include Normalizable
      # ~~~
      #
      # Any transform classes mixing in this module must have the following
      #   local variables present from where the `prepare_normalizer` method
      #   is called.
      #
      # - ignore_case: Boolean
      # - normalize: Hash to be passed to StringNormalizer
      #
      # In your `initialize` method, add the following line:
      #
      # ~~~
      #  @normalizer = prepare_normalizer(ignore_case, normalize)
      # ~~~
      module Normalizable
        ::Normalizable =
          Kiba::Extend::Transforms::Normalizable

        def prepare_normalizer(ignore_case, normalize)
          return nil if !ignore_case && !normalize

          norm_args = get_norm_args(ignore_case, normalize)
          Utils::StringNormalizer.new(**norm_args)
        end

        def get_norm_args(ignore_case, normalize)
          return normalize if !ignore_case && normalize
          return {xforms: [:lower]} if ignore_case && !normalize

          unless normalize.key?(:xforms)
            normalize[:xforms] = []
          end
          unless normalize[:xforms].include?(:lower)
            normalize[:xforms] << :lower
          end
        end
      end
    end
  end
end
