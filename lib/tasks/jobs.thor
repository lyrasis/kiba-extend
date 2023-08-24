require_relative "runnable"

# Tasks that list jobs and optionally run them
class Jobs < Runnable
  class_option :run, required: false, type: :boolean, default: false, aliases: :r,
    desc: "Whether to run the matching jobs. Default: false"
end
