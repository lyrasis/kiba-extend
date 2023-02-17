# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Namespace to organize transforms that work on MARC records from
      #   {Sources::Marc}, in {Jobs::MarcJob}s.
      #
      # These transforms depend heavily on configuration settings defined
      #   in {Kiba::Extend::Marc}, so definitely look at that documentation.
      #
      # Given that there are currently no plans to add a MARC Destination
      #   class, the purpose of these transforms is to extract data from
      #   MARC records into the Hash rows used by other transforms, and
      #   writable to CSV Destinations.
      #
      # This means that, a job will generally only use a single transform from
      #   this namespace, as the first transform in the job. Once the relevant
      #   MARC data is extracted into Hash rows, all the usual transforms can be
      #   applied.
      # @since 3.3.0
      module Marc
        ::Marc = Kiba::Extend::Transforms::Marc
      end
    end
  end
end
