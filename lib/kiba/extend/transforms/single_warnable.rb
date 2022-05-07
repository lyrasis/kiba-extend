# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module providing `do_warnings` method for transforms.
      #
      # If you have an input with 1000 rows missing an expected field, you don't want 1000 warnings to STDOUT, so
      #   this handles ensuring a single warning will be sent
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
      end
    end
  end
end
