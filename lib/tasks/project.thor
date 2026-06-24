# frozen_string_literal: true

class Project < Thor
  desc "empty_field_report", "write empty field report"
  method_option :tags,
    type: :array,
    required: true,
    aliases: "-t",
    desc: "One or more tags used to identify registry entries to report on"
  method_option :boolean_logic,
    enum: %w[and or],
    default: "and",
    aliases: "-b",
    desc: "Boolean operator used to query for more than one tag"
  method_option :output_path,
    type: :string,
    aliases: "-o",
    required: true,
    desc: "Where to write the report"
  def empty_field_report
    Kiba::Extend::Command::Project::EmptyFieldReport.call(
      tags: options[:tags].map(&:to_sym),
      boolean: options[:boolean_logic].to_sym,
      output: options[:output_path]
    )
  end
end
