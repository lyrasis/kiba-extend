require 'thor'

class Run < Runnable
  desc 'job KEY', 'runs the specified job'
  
  def job(key)
    preprocess_options
    run_job(key)
  end
end
