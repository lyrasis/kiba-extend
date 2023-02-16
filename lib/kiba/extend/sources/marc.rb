# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Sources
      # Given a binary MARC file containing one or more MARC records, yields one
      #   MARC record at a time, for processing.
      #
      # This is just a simple wrapper around `ruby-marc`'s `MARC::Reader`
      #   `:each` method. See that class' documentation at
      #   https://github.com/ruby-marc/ruby-marc/blob/main/lib/marc/reader.rb
      #   for more details about args that can be passed in to deal with
      #   character encoding.
      #
      # See [File Registry Entry documentation page](https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html)
      #   for more details on how to set up a Marc source in a project.
      #
      # @note Only transforms in the `Kiba::Extend::Transforms::Marc` namespace
      #   can initially be used on records from this source
      #
      # @note The class name is `Marc` instead of `MARC` because the `ruby-marc`
      #   gem already has the `MARC` namespace
      class Marc
        # @param filename [String] path to MARC binary file (.mrc, .dat, etc.)
        # @param args [Hash] of `MARC::Reader` optional keyword
        #   arguments. See documentation at:
        #   https://github.com/ruby-marc/ruby-marc/blob/main/lib/marc/reader.rb
        #   for more details
        def initialize(filename:, args: nil)
          if args
            @args = [filename, args]
          else
            @args = [filename]
          end
        end

        def each
          MARC::Reader.new(*args).each do |record|
            yield(record)
          end
        end

        private

        attr_reader :args
      end
    end
  end
end
