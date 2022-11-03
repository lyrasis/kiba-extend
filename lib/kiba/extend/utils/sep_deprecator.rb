# frozen_string_literal: true

require 'strscan'

module Kiba
  module Extend
    module Utils
      # Use to handle `sep` and `delim` params in Transforms classes that are
      #   deprecating the `sep` param in favor of `delim`, but haven't removed
      #   `sep` yet.
      class SepDeprecator
        attr_reader :delim

        # @param sep [String]
        # @param delim [String]
        # @param caller [#process]
        def initialize(sep:, delim:, calledby:)
          @sepval = sep
          @delimval = delim
          @calledby = calledby
        end

        def call
          if delimval && !sepval
            @delim = delimval
          elsif !delimval && sepval
            @delim = sepval
            warn("#{Kiba::Extend.warning_label}:\n"\
                          "  #{calledby.class}: `sep` parameter will be "\
                          "deprecated in a future release.\n"\
                          "TO FIX:\n"\
                          "  Change `sep` to `delim`"
                )
          elsif delimval && sepval
            @delim = delimval
            warn("#{Kiba::Extend.warning_label}:\n"\
                 "  #{calledby.class}: `sep` and `delim` parameters "\
                 "given. `delim` value used. `sep` value ignored. "\
                 "`sep` will be deprecated in a future release.\n"\
                 "TO FIX:\n  Remove `sep` param"
                )
          else
            fail(ArgumentError, "missing keyword: :delim")
          end
          self
        end

        private

        attr_reader :sepval, :delimval, :calledby
      end
    end
  end
end
