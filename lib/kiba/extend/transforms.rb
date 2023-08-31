# frozen_string_literal: true

module Kiba
  module Extend
    # Namespace for modules that organize Kiba transforms.
    #
    # Note that a Kiba transform is just a class that implements a public
    #   `process` method that takes a row as its parameter and returns the
    #   transformed row.
    #
    # Because all Kiba transforms require this, that method is
    #   commented as "private" for the sake of creating non-repetitive
    #   documentation.
    #
    # ## Notes on commonly used parameters in tranforms
    #
    # ### fields
    # Expects an Array of field names. The field names should be Symbols unless
    #   you have overridden the default CSV converter which symbolizes header
    #   values.
    #
    # `transform My::Transform, fields: %i[title author]`
    #
    # Since 2.5.2, you may also pass a single Symbol and it will be wrapped in
    #   an Array for you automagically.
    #
    # `transform My::Transform, fields: :title`
    #
    # If a transform mixes in {Allable}, then you can specify that it should be
    #   applied to all fields:
    #
    # `transform My::Transform, fields: :all`
    #
    module Transforms
    end
  end
end
