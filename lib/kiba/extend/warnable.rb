# frozen_string_literal: true

module Kiba
  module Extend
    # Mixin module containing Kiba::Extend.warn method
    module Warnable
      # @param str [String] the content of the warning message
      # @param ws [String] whitespace to separate {Kiba::Extend.warning_label}
      #   and `str`
      # @return [String] prepending {Kiba::Extend.warning_label} to the given
      #   string
      def warn(str, ws: " ") = "#{Kiba::Extend.warning_label}#{ws}#{str}"
    end
  end
end
