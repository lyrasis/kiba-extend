require 'thor'

class Run < Thor  
  desc 'job KEY', 'runs the specified job'
  def job(key)
    preprocess_options
    
    job = resolve_job(key)
    exit if job == :failure

    creator = resolve_creator(job)
    exit if creator == :failure

    creator.call
  end
end
