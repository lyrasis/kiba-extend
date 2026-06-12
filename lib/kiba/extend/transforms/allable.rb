# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module providing `finalize_fields` method for transforms that
      #   accept `fields: :all`.
      #
      # ## Usage
      #
      # Any transform classes mixing in this module must have `@fields` as an
      #   instance variable and `fields` as an attr_reader.
      #
      # Set the `fields` instance variable from user input as follows:
      #
      # ~~~ ruby
      #  @fields = [fields].flatten
      # ~~~
      #
      # Add the following line as the first thing in the `process` method:
      #
      # ~~~ ruby
      # finalize_fields(row) unless fields_set
      # ~~~
      #
      # If there is an `omit_from_all_fields` attr_reader set, these fields will
      #   be removed from the finalized list of all fields.
      # @since 2.8.0
      module Allable
        ::Allable = Kiba::Extend::Transforms::Allable

        module_function

        def fields_set
          @fields_set
        end
        private_class_method :fields_set

        def finalize_fields(row)
          if fields == [:all] && !row.key?(:all)
            set_fields(row)
          end

          @fields_set = true
        end
        private_class_method :finalize_fields

        def set_fields(row)
          @fields = if instance_variable_defined?(:@omit_from_all_fields)
            row.keys - @omit_from_all_fields
          else
            row.keys
          end
        end
        private_class_method :set_fields
      end
    end
  end
end
