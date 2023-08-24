# frozen_string_literal: true

module Kiba
  module Extend
    module Command
      module Run
        extend Runnable

        module_function

        # @param key [Symbol, String] registry key for job, i.e. prep__loan_purposes
        def job(key)
          run_job(key)
        end
      end
    end
  end
end
