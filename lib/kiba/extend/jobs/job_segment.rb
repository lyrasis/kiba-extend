module Kiba
  module Extend
    module Jobs
      module JobSegmenter
        def job_segment(&source_as_block)
          source_as_block
        end
      end
    end
  end
end
