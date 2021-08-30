# frozen_string_literal: true

module Kiba
  module Extend
    module SourceDestRegistry
      extend self

      # Registry of known source/destination classes and whether they require a path
      #
      # Enumerable and Lambda are 'in-memory' and useful for testing and possibly
      #   virtual transforms on the fly. See an example of use at:
      #   https://github.com/thbar/kiba-common/blob/master/test/test_lambda_destination.rb
      def requires_path?(klass)
        data = {
          nil => false,
          Kiba::Extend::Destinations::CSV => true,
          Kiba::Common::Destinations::CSV => true,
          Kiba::Common::Destinations::Lambda => false,
          Kiba::Common::Sources::CSV => true,
          Kiba::Common::Sources::Enumerable => false
        }
        data[klass]
      end

      def file_options(klass)
        data = {
          nil => nil,
          Kiba::Extend::Destinations::CSV => Kiba::Extend.csvopts,
          Kiba::Common::Destinations::CSV => Kiba::Extend.csvopts,
          Kiba::Common::Destinations::Lambda => Kiba::Extend.lambdaopts,
          Kiba::Common::Sources::CSV => Kiba::Extend.csvopts,
          Kiba::Common::Sources::Enumerable => nil
        }
        data[klass]
      end

      def labeled_options(klass)
        data = {
          nil => nil,
          Kiba::Extend::Destinations::CSV => { options_label(klass) => file_options(klass) },
          Kiba::Common::Destinations::CSV => { options_label(klass) => file_options(klass) },
          Kiba::Common::Destinations::Lambda => { options_label(klass) => file_options(klass) },
          Kiba::Common::Sources::CSV => { options_label(klass) => file_options(klass) },
          Kiba::Common::Sources::Enumerable => nil
        }
        data[klass]
      end

      # The Symbol used for the options in the Kiba Source/Destination file configuration hash
      def options_label(klass)
        data = {
          nil => nil,
          Kiba::Extend::Destinations::CSV => :csv_options,
          Kiba::Common::Destinations::CSV => :csv_options,
          Kiba::Common::Destinations::Lambda => :options,
          Kiba::Common::Sources::CSV => :csv_options,
          Kiba::Common::Sources::Enumerable => nil
        }
        data[klass]
      end
    end
  end
end
