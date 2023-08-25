# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Transforms
      module Marc
        # Namespace for MARC transforms that read in **and** output MARC,
        #   selecting or rejecting records to output, based on given
        #   criteria
        module FilterRecords
        end
      end
    end
  end
end
