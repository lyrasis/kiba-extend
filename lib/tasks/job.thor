# frozen_string_literal: true

require "thor"

class Job < Thor
  desc "graph JOB", "Render and save dependency graph for given job"
  def graph(job)
    unless mermaid_cli_installed?
      puts "mmd-cli (Mermaid CLI) command not installed or not found on path. "\
        "See README for installation instructions if you wish to use this "\
        "command."
      exit(1)
    end

    mermaid = Kiba::Extend.registry
      .resolve(job.to_sym)
      .mermaid

    dir = Kiba::Extend::ProjectConfig.graph_dir
    unless dir
      puts "TIP: Add `Kiba::Extend::ProjectConfig.config.graph_dir = "\
        "\"path_to_directory_for_your_project\" to your project config, "\
        "so your graphs can be saved with your other project files."
    end

    mmd_dir = dir || File.join(Kiba::Extend.ke_dir, "data")
    FileUtils.mkdir_p(mmd_dir) unless Dir.exist?(mmd_dir)

    mmd_path = File.join(mmd_dir, "#{job}.mmd")
    File.open(mmd_path, "w") { |f| f << mermaid }

    pdf_path = File.join(mmd_dir, "#{job}.pdf")
    `mmd-cli -i #{mmd_path} -o #{pdf_path} -f`

    `open #{pdf_path}`
    exit(0)
  end

  no_commands do
    def mermaid_cli_installed?
      result = `which mmd-cli`
      true unless result.empty?
    end
  end
end
