# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      class PreJobNukeTask < PreJobTask
        class << self
          def call
            new.call
          end
        end

        def call
          return unless runnable?

          dirs.each do |dir|
            if Kiba::Extend.pre_job_task_action == :recursive_nuke
              puts "Deleting files and directories from #{dir}..."
              Dir.each_child(dir) { |f| FileUtils.rm_rf("#{dir}/#{f}") }
            elsif Kiba::Extend.pre_job_task_action == :nuke
              puts "Deleting files from #{dir}..."
              Dir.each_child(dir) { |f| FileUtils.rm("#{dir}/#{f}") }
            end
          end
        end

        private

        def runnable?
          true if mode && dirs && !dirs.empty?
        end
      end
    end
  end
end
