require 'thor'

class Run < Thor  
  desc 'jobs', 'runs the specified jobs'
  option :keys, required: true, type: :array, aliases: :k,
         desc: 'Registry keys for the job to run'

  def jobs
    opts = options.dup
    opts.delete(:keys)

    options[:keys].each do |key|
      job = resolve_job(key)
      next if job == :failure

      creator = resolve_creator(job)
      next if creator == :failure

      creator.call
    end
  end
end
