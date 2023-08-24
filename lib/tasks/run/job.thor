# frozen_string_literal: true

require "thor"

class Run < Runnable
  desc "job KEY", "runs the specified job"

  def job(key)
    preprocess_options
    Kiba::Extend::Utils::PreJobTask.call
    Kiba::Extend::Command::Run.job(key)
  end
end
