# frozen_string_literal: true

require "base64"

module Kiba
  module Extend
    module Utils
      # @since 2.7.1.65
      # rubocop:todo Layout/LineLength
      # Raised if the values in fields passed to {FingerprintCreator} contain the delim value the class was
      # rubocop:enable Layout/LineLength
      #   initialized with
      class DelimInValueFingerprintError < StandardError
      end
    end
  end
end
