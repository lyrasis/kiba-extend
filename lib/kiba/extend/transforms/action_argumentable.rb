# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module providing consistent validation of `action` argument
      #
      # @since 4.0.0
      module ActionArgumentable
        ::ActionArgumentable = Kiba::Extend::Transforms::ActionArgumentable

        module_function

        # @raise {Kiba::Extend::InvalidActionError} if action is not :keep
        #   or :reject
        def validate_action_argument(action)
          return if %i[keep reject].any?(action)

          fail Kiba::Extend::InvalidActionError.new(
            "#{self.class.name} `action` must be :keep or :reject"
          )
        end
        private_class_method :validate_action_argument
      end
    end
  end
end
