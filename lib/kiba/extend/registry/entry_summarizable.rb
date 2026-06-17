# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Mixin methods for deriving FileRegistryEntry summary for display
      module EntrySummarizable
        # Printable string summarizing the Entry, called by project applications
        # @return [String]
        def summary
          [
            summary_first_line,
            summary_desc,
            summary_path,
            summary_creator,
            summary_lookup_on,
            "\n"
          ].compact
            .join("\n")
        end

        private

        def summary_first_line
          return key.to_s if tags.blank?

          "#{key} -- tags: #{tags.join(", ")}"
        end

        def padded_desc
          [
            padding,
            desc.chomp
              .gsub("\n", "\n#{padding}")
          ].join
        end

        def summary_desc
          return if desc.blank?

          sep = "#{padding}~~~~"
          ["#{sep} Job description", padded_desc, sep].join("\n")
        end

        def summary_path
          return unless path

          prefix = supplied ? "Input file path" : "Job output written to"
          ["#{padding}#{prefix}", path].join(": ")
        end

        def summary_creator
          return "#{padding}n/a - Supplied file" unless creator

          "#{padding}Job definition: #{creator}"
        end

        def summary_lookup_on
          return unless lookup_on

          "#{padding}Lookup on: :#{lookup_on}"
        end

        def padding = "    "
      end
    end
  end
end
