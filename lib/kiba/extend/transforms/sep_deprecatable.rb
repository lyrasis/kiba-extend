# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module to handle `sep` and `delim` params in Transforms classes
      #   that are deprecating the `sep` param in favor of `delim`, but haven't
      #   removed `sep` yet.
      #
      # ## Use/implementation
      #
      # Classes deprecating `sep` should:
      #
      # 1.
      #
      # ```
      # include SepDeprecatable
      # ```
      #
      # 2. Include in :initialize params:
      #
      # ```
      # sep: nil, delim: nil
      # ```
      #
      # 3. Include in class :initialize method:
      #
      # ```
      #   @delim = usedelim(sepval: sep, delimval: delim, calledby: self)
      # ```
      #
      # @since 3.3.0
      module SepDeprecatable
        # @param sepval [String] `sep` value passed to class
        # @param delimval [String] `delim` value passed to class
        # @param calledby Instance of the class in which sep is being deprecated
        # @param default [nil, String] default sep/nil value used if none given
        def usedelim(sepval:, delimval:, calledby:, default: nil)
          if delimval && !sepval
            delimval
          elsif !delimval && sepval
            warn("#{Kiba::Extend.warning_label}:\n"\
                 "  #{calledby.class}: `sep` parameter will be "\
                 "deprecated in a future release.\n"\
                 "TO FIX:\n"\
                 "  Change `sep` to `delim`"
                )
            sepval
          elsif delimval && sepval
            warn("#{Kiba::Extend.warning_label}:\n"\
                 "  #{calledby.class}: `sep` and `delim` parameters "\
                 "given. `delim` value used. `sep` value ignored. "\
                 "`sep` will be deprecated in a future release.\n"\
                 "TO FIX:\n  Remove `sep` param"
                )
            delimval
          else
            return default if default

            fail(ArgumentError, "#{calledby.class}: missing keyword: :delim")
          end
        end
      end
    end
  end
end
