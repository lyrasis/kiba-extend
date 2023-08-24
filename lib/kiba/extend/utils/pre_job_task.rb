# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      class PreJobTask
        class << self
          def call
            use_setting = :pre_job_task_run
            return unless Kiba::Extend.respond_to?(use_setting) && Kiba::Extend.send(use_setting)

            action = Kiba::Extend.pre_job_task_action
            return unless action && valid_action?(action)

            case action
            when :backup then Kiba::Extend::Utils::PreJobBackupTask.call
            when :nuke then Kiba::Extend::Utils::PreJobNukeTask.call
            end
          end

          private

          def valid_action?(action_setting)
            return true if %i[backup nuke].any?(action_setting)

            msg = "PreJobTask cannot be run because :pre_job_task_action is not :backup or :nuke"
            warn(msg)
            false
          end
        end

        def initialize
          return unless configured?(:pre_job_task_mode)

          mode_setting = Kiba::Extend.pre_job_task_mode
          return unless mode_setting == :job

          @mode = mode_setting
          return unless configured?(:pre_job_task_directories)

          dirs_setting = Kiba::Extend.pre_job_task_directories
          return unless valid_dirs?(dirs_setting)

          @dirs = dirs_setting.select { |dir| Dir.exist?(dir) }
        end

        private

        attr_reader :dirs, :action, :mode

        def configured?(meth)
          unless Kiba::Extend.send(meth).nil?
            return true if Kiba::Extend.respond_to?(meth)
          end

          msg = "PreJobTask cannot be run because no #{meth} setting is configured"
          warn(msg)
          false
        end

        def valid_dirs?(dirs_setting)
          return false if dirs_setting.empty?

          nonexist = dirs_setting.reject { |dir| Dir.exist?(dir) }
          return true if nonexist.empty?

          if nonexist == dirs_setting
            msg = ["PreJobTask cannot be run because no :pre_job_task_directories exist:"]
            nonexist.each { |dir| msg << dir }
            warn(msg.join("\n"))
            false
          else
            msg = ["Some PreJobTask directories will be skipped they do not exist:"]
            nonexist.each { |dir| msg << dir }
            warn(msg.join("\n"))
            true
          end
        end
      end
    end
  end
end
