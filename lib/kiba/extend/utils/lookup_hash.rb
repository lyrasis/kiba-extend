# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      class LookupHash
        attr_reader :hash

        # @param keycolumn [Symbol] field name on which rows are grouped/looked up
        def initialize(keycolumn:)
          @keycolumn = keycolumn
          @hash = {}
        end

        # @param record [Hash{Symbol => String}] 
        def add_record(record)
          key = record.fetch(keycolumn, nil)
          hash.key?(key) ? hash[key] << record : hash[key] = [record]
        end
        
        private

        attr_reader :keycolumn
      end
    end
  end
end

