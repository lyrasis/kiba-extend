# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      module SourceDestRegistry
        module_function

        def default_args(klass)
          data = {
            nil => false,
            Kiba::Common::Destinations::CSV =>
              {filename: path}.merge(labeled_options(klass)),
            Kiba::Common::Destinations::Lambda => false,
            Kiba::Common::Sources::CSV => true,
            Kiba::Common::Sources::Enumerable => false,
            Kiba::Extend::Destinations::CSV =>
              {filename: path}.merge(labeled_options(klass)),
            Kiba::Extend::Destinations::JsonArray => {filename: path},
            Kiba::Extend::Destinations::Marc => {filename: path},
            Kiba::Extend::Sources::Marc =>
              {path: path}.merge(labeled_options(klass))
          }
          data[klass]
        end

        # For each class that may be used as a registry entry `dest_class`,
        #   gives the source class that should be used to read that registry entry
        #   when it is used as a source in a job
        # @note Entries having destinations mapped to nil here cannot be
        #   used as sources in jobs.
        def dest_src_mapping(klass)
          data = {
            Kiba::Common::Destinations::CSV => Kiba::Common::Sources::CSV,
            Kiba::Common::Destinations::Lambda => nil,
            Kiba::Extend::Destinations::CSV => Kiba::Common::Sources::CSV,
            Kiba::Extend::Destinations::JsonArray => nil,
            Kiba::Extend::Destinations::Marc => Kiba::Extend::Sources::Marc
          }
          data[klass]
        end

        # Registry of known source/destination classes and whether they require a path
        #
        # Enumerable and Lambda are 'in-memory' and useful for testing and possibly
        #   virtual transforms on the fly. See an example of use at:
        #   https://github.com/thbar/kiba-common/blob/master/test/test_lambda_destination.rb
        def requires_path?(klass)
          data = {
            nil => false,
            Kiba::Common::Destinations::CSV => true,
            Kiba::Common::Destinations::Lambda => false,
            Kiba::Common::Sources::CSV => true,
            Kiba::Common::Sources::Enumerable => false,
            Kiba::Extend::Destinations::CSV => true,
            Kiba::Extend::Destinations::JsonArray => true,
            Kiba::Extend::Destinations::Marc => true,
            Kiba::Extend::Sources::Marc => true
          }
          data[klass]
        end

        def default_file_options(klass)
          data = {
            nil => nil,
            Kiba::Common::Destinations::CSV => Kiba::Extend.csvopts,
            Kiba::Common::Destinations::Lambda => Kiba::Extend.lambdaopts,
            Kiba::Common::Sources::CSV => Kiba::Extend.csvopts,
            Kiba::Common::Sources::Enumerable => nil,
            Kiba::Extend::Destinations::CSV => Kiba::Extend.csvopts,
            Kiba::Extend::Destinations::JsonArray => nil,
            Kiba::Extend::Destinations::Marc => nil,
            Kiba::Extend::Sources::Marc => nil
          }
          data[klass]
        end

        def labeled_options(klass)
          data = {
            nil => nil,
            Kiba::Common::Destinations::CSV =>
              { options_label(klass) => default_file_options(klass) },
            Kiba::Common::Destinations::Lambda =>
              { options_label(klass) => default_file_options(klass) },
            Kiba::Common::Sources::CSV =>
              { options_label(klass) => default_file_options(klass) },
            Kiba::Common::Sources::Enumerable => {},
            Kiba::Extend::Destinations::CSV =>
              { options_label(klass) => default_file_options(klass) },
            Kiba::Extend::Destinations::JsonArray => {},
            Kiba::Extend::Destinations::Marc => {},
            Kiba::Extend::Sources::Marc =>
              { options_label(klass) => default_file_options(klass) }
          }
          data[klass]
        end

        # The Symbol used for the options in the Kiba Source/Destination file
        #   configuration hash
        def options_label(klass)
          data = {
            nil => nil,
            Kiba::Common::Destinations::CSV => :csv_options,
            Kiba::Common::Destinations::Lambda => :options,
            Kiba::Common::Sources::CSV => :csv_options,
            Kiba::Common::Sources::Enumerable => nil,
            Kiba::Extend::Destinations::CSV => :csv_options,
            Kiba::Extend::Destinations::JsonArray => nil,
            Kiba::Extend::Destinations::Marc => nil,
            Kiba::Extend::Sources::Marc => :args
          }
          data[klass]
        end

        # The Symbol used for the file options when calling source class as a
        #   {Kiba::Extend::Lookup}
        def lookup_options_label(klass)
          data = {
            Kiba::Common::Sources::CSV => :csvopt,
          }
          data[klass]
        end

      end
    end
  end
end
