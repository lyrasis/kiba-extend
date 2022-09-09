require 'thor'

class Run < Runnable
  desc 'job KEY', 'runs the specified job'
  
  def job(key)
    preprocess_options
    Kiba::Extend::Command::Run.job(key)
  end
end
