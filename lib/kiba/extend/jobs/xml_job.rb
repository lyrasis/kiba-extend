# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Job with one XmlDir source, one destination, and zero-to-n lookups.
      #
      # @note The source yields Nokogiri::XML::Document objects, so this
      #   job is treated as a generic template (no conversion of records
      #   to hashes)
      class XmlJob < AbstractNoInitialDataConversionJob
      end
    end
  end
end
