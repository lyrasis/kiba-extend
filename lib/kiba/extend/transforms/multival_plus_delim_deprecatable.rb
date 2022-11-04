# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module to handle deprecating `multival` param in transforms having
      #   both `multival` and `delim` params.
      #
      # ## Use/implementation
      #
      # Classes deprecating `multival` should:
      #
      # ONE:
      #
      # ```
      # include MultivalPlusDelimDeprecatable
      # ```
      #
      # TWO: Change :initialize params from:
      #
      # ```
      # multival: trueorfalse
      # ```
      #
      # to:
      #
      # ```
      # multival: omitted = true
      # ```
      #
      # THREE: Include in class :initialize method:
      #
      # ```
      #   @multival = set_multival(multival, omitted, self)
      # ```
      #
      # FOUR: **ONLY if current default value for :multival param == true:**
      #   Define a private :multival_default method that returns true:
      #
      # ```
      # def multival_default
      #   true
      # end
      # ````
      module MultivalPlusDelimDeprecatable
        def set_multival(multival, omitted, calledby)
          if omitted
            multival_default
          else
            warn("#{Kiba::Extend.warning_label}:\n"\
                 "  #{calledby.class}: #{warning_body}"
                )
            multival
          end
        end

        def multival_default
          false
        end
        private :multival_default

        def warning_body
          "`multival` parameter will be deprecated in a future release. "\
            "Multival behavior will be triggered by passing a `delim` "\
            "argument.\nTO FIX:\n  Delete the `multival` parameter"
        end
        private :warning_body
      end
    end
  end
end
