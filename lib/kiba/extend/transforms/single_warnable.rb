# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module providing `do_warnings` method for transforms.
      #
      # rubocop:todo Layout/LineLength
      # If you have an input with 1000 rows missing an expected field, you don't want 1000 warnings to STDOUT, so
      # rubocop:enable Layout/LineLength
      #   this handles ensuring a single warning will be sent
      #
      # ## Usage
      # Transform classes using this should: `include SingleWarnable`.
      #
      # rubocop:todo Layout/LineLength
      # The `initialize` method of a transform using this mixin should call `setup_single_warning`. Then,
      # rubocop:enable Layout/LineLength
      # rubocop:todo Layout/LineLength
      #   `add_single_warning("The warning message")` can be used from anywhere else in the transform.
      # rubocop:enable Layout/LineLength
      #
      # @since 2.8.0
      module SingleWarnable
        ::SingleWarnable = Kiba::Extend::Transforms::SingleWarnable

        module_function

        def add_single_warning(warning)
          return if @single_warnings.key?(warning)

          @single_warnings[warning] = nil
          warn("#{Kiba::Extend.warning_label}: #{warning}")
        end
        private_class_method :add_single_warning

        def setup_single_warning
          instance_variable_set(:@single_warnings, {})
        end
        private_class_method :setup_single_warning

        def single_warnings
          @single_warnings
        end
      end
    end
  end
end
