# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      module JobSegmentable
        def job_segment(&source_as_block)
          source_as_block
        end
      end
    end
  end
end
