require 'thor'

class Run < Runnable
  desc 'jobs', 'runs the specified jobs'
  option :keys, required: true, type: :array, aliases: :k,
         desc: 'Registry keys for the job to run'

  def jobs
    preprocess_options
    options[:keys].each{ |key| run_job(key) }
  end
end
