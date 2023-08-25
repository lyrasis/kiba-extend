# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      class PreJobBackupTask < PreJobTask
        class << self
          def call
            new.call
          end
        end

        def initialize
          setting = :pre_job_task_backup_dir
          return unless configured?(setting)

          backup_setting = Kiba::Extend.send(setting)
          return unless valid_backup?(backup_setting)

          @backup_dir = backup_setting

          @timestamp = Time.now.strftime("%y-%m-%d_%H-%M")
          super
        end

        def call
          return unless runnable?

          dirs.each { |dir| backup(dir) }
        end

        private

        attr_reader :backup_dir, :timestamp

        def backed_up_dir_name(dir)
          dir.split("/").last
        end

        def backup(dir)
          puts "Backing up #{dir}..."
          bdir = File.join(backup_dir, backed_up_dir_name(dir))
          FileUtils.mkdir_p(bdir) unless Dir.exist?(bdir)
          Dir.each_child(dir) { |file| backup_file(file, dir, bdir) }
        end

        def backup_file(file, dir, bdir)
          nowpath = File.join(dir, file)
          newpath = File.join(bdir, "#{timestamp}_#{file}")
          FileUtils.mv(nowpath, newpath)
        end

        def runnable?
          true if mode && dirs && !dirs.empty? && backup_dir
        end

        def valid_backup?(val)
          return true if Dir.exist?(val)

          begin
            FileUtils.mkdir_p(val)
          rescue
            # rubocop:todo Layout/LineLength
            msg = "PreJobTask cannot be run because :pre_job_task_backup_dir does not exist and cannot be created"
            # rubocop:enable Layout/LineLength
            warn(msg)
            false
          else
            true
          end
        end
      end
    end
  end
end
