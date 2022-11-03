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
      module SepDeprecatable
        def usedelim(sepval:, delimval:, calledby:)
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
            fail(ArgumentError, "#{calledby.class}: missing keyword: :delim")
          end
        end
      end
    end
  end
end
