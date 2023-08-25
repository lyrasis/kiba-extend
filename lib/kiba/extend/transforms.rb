# frozen_string_literal: true

module Kiba
  module Extend
    # Namespace for modules that organize Kiba transforms.
    #
    # rubocop:todo Layout/LineLength
    # Note that a Kiba transform is just a class that implements a public `process` method that
    # rubocop:enable Layout/LineLength
    #   takes a row as its parameter and returns the transformed row.
    #
    # Because all Kiba transforms require this, that method is
    # rubocop:todo Layout/LineLength
    #   commented as "private" for the sake of creating non-repetitive documentation.
    # rubocop:enable Layout/LineLength
    #
    # ## Notes on commonly used parameters in tranforms
    #
    # ### fields
    # rubocop:todo Layout/LineLength
    # Expects an Array of field names. The field names should be Symbols unless you have
    # rubocop:enable Layout/LineLength
    #   overridden the default CSV converter which symbolizes header values.
    #
    # `transform My::Transform, fields: %i[title author]`
    #
    # rubocop:todo Layout/LineLength
    # Since 2.5.2, you may also pass a single Symbol and it will be wrapped in an Array for you
    # rubocop:enable Layout/LineLength
    #   automagically.
    #
    # `transform My::Transform, fields: :title`
    #
    # rubocop:todo Layout/LineLength
    # If a transform mixes in {Allable}, then you can specify that it should be applied to all fields:
    # rubocop:enable Layout/LineLength
    #
    # `transform My::Transform, fields: :all`
    #
    module Transforms
    end
  end
end
