# frozen_string_literal: true

require_relative "base_job"

module Kiba
  module Extend
    module Jobs
      # Job with one MARC source, one destination, and zero-to-n lookups.
      #
      # @note The first transform called in a `MarcJob` must be one from the
      #   {Kiba::Extend::Transforms::Marc} namespace.
      # @since 3.3.0
      class MarcJob < BaseJob
        private

        def initial_transforms
          Kiba.job_segment do
            transform { |r|
              @srcrows += 1
              r
            }
          end
        end

        def final_transforms
          Kiba.job_segment do
            transform { |r|
              @outrows += 1
              r
            }
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
