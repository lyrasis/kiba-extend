# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        module Jobs
          module ProcessReturnedFile
            module_function

            def job(source:, dest:, xforms:)
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: source,
                  destination: dest
                },
                transformer: [xforms]
              )
            end
          end
        end
      end
    end
  end
end
