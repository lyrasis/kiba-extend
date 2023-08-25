# frozen_string_literal: true

require_relative "runnable"

# Tasks that list jobs and optionally run them
class Jobs < Runnable
  # rubocop:todo Layout/LineLength
  class_option :run, required: false, type: :boolean, default: false, aliases: :r,
    # rubocop:enable Layout/LineLength
    desc: "Whether to run the matching jobs. Default: false"
end
