# frozen_string_literal: true

require_relative 'base_job'

module Kiba
  module Extend
    module Jobs
      # Job with one source, one destination, and zero-to-n lookups
      class Job < BaseJob
        private
        
        def initial_transforms
          Kiba.job_segment do
            transform { |r| r.to_h }
            transform { |r| @srcrows += 1; r }
          end
        end

        def final_transforms
          Kiba.job_segment do
            transform { |r| @outrows += 1; r }
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
