# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Job with one source, one destination, and zero-to-n lookups, for
      #   source data that is *already* in the shape transforms expect it in
      #   (i.e. some non-Hash record object), so (unlike {Job}) no `to_h`
      #   conversion is applied to source rows. We created this superclass
      #   to avoid duplicating logic verbatim in XML and Marc jobs, but
      #   it would work for any non-Hash record source.
      #
      # @abstract Subclass to get this behavior for a specific source
      #   record type, initially {MarcJob} and {XmlJob}
      class AbstractNoInitialDataConversionJob < BaseJob
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
