# frozen_string_literal: true

module Kiba
  module Extend
    module Command
      module Project
        class EmptyFieldReport
          def self.call(...)
            new(...).call
          end

          attr_reader :tags, :output, :boolean

          # @param tags [Array<Symbol>] used to identify registry entries to
          #   report on
          # @param output [String] path to output file
          # @param boolean [:and, :or] used to combine multiple tags
          def initialize(tags:, output:, boolean: :and)
            @tags = tags
            @output = output
            @boolean = boolean
          end

          def call
            headers = %i[table field]
            CSV.open(output, "w", headers: headers,
              write_headers: true) do |csv|
              entries.map { |entry| id_empty_fields(entry) }
                .flatten
                .each { |row| csv << row.values_at(*headers) }
            end

            puts "Wrote empty field report to #{output}"
          end

          private

          def entries
            if boolean == :or
              return Kiba::Extend::Command::Jobs::TaggedOr.call(tags)
            end

            Kiba::Extend::Command::Jobs::TaggedAnd.call(tags)
          end

          def id_empty_fields(entry)
            path = entry.path
            puts "Checking #{path} for empty fields"
            table = path.basename(".csv")
            data = CSV.parse(File.read(path), **Kiba::Extend.csvopts)
            data.by_col!
            data.headers.select { |hdr| data[hdr].all?(&:blank?) }
              .map { |hdr| {table: table, field: hdr} }
          end
        end
      end
    end
  end
end
