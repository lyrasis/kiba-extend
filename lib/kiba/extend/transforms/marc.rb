# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Namespace to organize transforms that work on MARC records from
      #   {Sources::Marc}
      #
      # These transforms depend heavily on configuration settings defined
      #   in {Kiba::Extend::Marc}, so definitely look at that documentation.
      #
      # Given that there are currently no plans to add a MARC Destination
      #   class, the purpose of these transforms is to extract data from
      #   MARC records into the Hash rows used by other transforms, and
      #   writable to CSV Destinations.
      module Marc
        ::Marc = Kiba::Extend::Transforms::Marc
      end
    end
  end
end
