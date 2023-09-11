# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Job taking a JSON source that yields `Hash`es, and writing
      #   to a CSV (or other tabular) destination expecting the same
      #   headers/fields in every row
      #
      # @since 4.0.0
      class JsonToCsvJob < BaseJob
        private

        def initial_transforms
          Kiba.job_segment do
            transform do |r|
              @srcrows += 1
              r
            end
          end
        end

        def final_transforms
          Kiba.job_segment do
            transform Clean::EnsureConsistentFields
            transform do |r|
              @outrows += 1
              r
            end
          end
        end

        def pre_process
          Kiba.job_segment do
            pre_process do
              @srcrows = 0
              @outrows = 0
            end
          end
        end

        def config
          Kiba.parse do
          end.config
        end

        def post_process
          Kiba.job_segment do
            post_process do
            end
          end
        end
      end
    end
  end
end
