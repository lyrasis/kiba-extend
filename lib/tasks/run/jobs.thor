# frozen_string_literal: true

require "thor"

class Run < Runnable
  desc "jobs", "runs the specified jobs"
  option :keys, required: true, type: :array, aliases: :k,
    desc: "Registry keys for the job to run"

  def jobs
    run_jobs(options[:keys])
  end
end
