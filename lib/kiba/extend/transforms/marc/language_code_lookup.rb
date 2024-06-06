# frozen_string_literal: true

require "net/http"
require "uri"

module Kiba
  module Extend
    module Transforms
      module Marc
        # Look up MARC List for Languages codes and provide preferred
        # label value
        #
        # @example Known code
        #   row = {code: "eng"}
        #   result = Marc::LanguageCodeLookup.new(source: :code).process(row)
        #   expect(result).to eq(row.merge({language: "English"}))
        #
        # @example Unknown code
        #   row = {code: "foo"}
        #   result = Marc::LanguageCodeLookup.new(source: :code).process(row)
        #   expect(result).to eq(row.merge({language: nil}))
        class LanguageCodeLookup
          # @param source [Symbol] row field containing language code to
          #   look up
          # @param target [Symbol] row field into which language label value
          #   will be written
          def initialize(source:, target: :language)
            @source = source
            @target = target
            @host = URI.parse("https://id.loc.gov").hostname
          end

          # @param row [Hash{ Symbol => String, nil }]
          # @return [Hash{ Symbol => String, nil }]
          def process(row)
            Net::HTTP.start(host, use_ssl: true) do |http|
              row[target] = api_result(http, row[source])
            end
            row
          end

          private

          attr_reader :source, :target, :host

          def api_result(http, code)
            return if code.blank?

            http.head("/vocabulary/languages/#{code}")["x-preflabel"]
          end
        end
      end
    end
  end
end
