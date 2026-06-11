# frozen_string_literal: true

module Kiba
  module Extend
    # Optional settings for creating sequenced FCAR processes in a
    #   project.
    #
    # This code's original use was in an abstract project, where it was used to
    #   determine whether a client project was using a given
    #   facilitated cleanup and remapping (FCAR) process or not, and
    #   thus automagically determine the correct source job
    #   for a given FCAR process in a given client project
    module Fcar
      module_function

      extend Dry::Configurable

      # @return [Array<Module>] FCAR processes intended for use in
      #   your project, for which there are not yet any files
      setting :pending_processes, reader: true, default: []

      # @return [Symbol] job key of job whose output should be
      #   used as input for initial FCAR process
      setting :base_source, reader: true, default: :your__jobkey

      # @return [Array<String>, Hash{String => String}] All FCAR processes
      #   defined for your project, in the order they are run. Use the Hash
      #   form if you wish to provide comments on the processes.
      #
      # Sample CHUTE for a reusable codebase on which multiple client projects
      #   can be based:
      #
      # - ObjectCounts
      # -
      # The order of the overall CHUTE is NOT the order you must
      #   complete all the FCAR processes. For instance, your migration
      #   process may have you starting with the 2, not
      #   Itemandboxcount. Without an Itemandboxcount process set up,
      #   the `source` for AgencyMuseumNameCleanup will be the `base_source`.
      #   If/when you set up an Itemandboxcount process, its `source` will
      #   be `base_source` and AgencyMuseumNameCleanup's `source` will become
      #   the output of the merge job for Itemandboxcount.
      #
      # Within a group, you can leave out steps if they aren't needed. For
      #   instance, if no site values are multi-value, you can skip
      #   SiteSplit. If multiple processs from a group are needed, they must
      #   be done in order.
      #
      # Any hard-dependencies on order between processes and/or groups should
      #   be specified in the comments.
      setting :chute,
        reader: true,
        default: [],
        constructor: ->(default) do
          return {} if default.empty?
          return default if default.is_a?(Hash)

          default.map { |e| [e, ""] }.to_h
        end

      # @return [Array<Module>] FCAR processes used in client project
      def processes
        chute.keys
          .map { |name| project_process(name) }
          .compact
          .select { |mod| active?(mod) && valid?(mod) }
      end

      def previous_merged(mod)
        idx = processes.find_index(mod)
        fail(Kiba::Extend::UnknownFcarConfigError.new(mod)) unless idx
        return base_source if idx == 0

        processes[idx - 1].merge_job
      end

      def final_merged = processes[-1]&.merge_job || base_source

      def project_process(name)
        Kiba::Extend.config_namespaces.map { |ns| constant(ns, name) }
          .compact
          .last
      end
      private_class_method :project_process

      def constant(ns, name)
        "#{ns}::#{name}".constantize
      rescue NameError
        nil
      end
      private_class_method :constant

      def active?(mod)
        !mod.send(:provided_worksheets).empty? ||
          pending_processes.include?(mod)
      end
      private_class_method :active?

      def valid?(mod)
        unless mod.respond_to?(:merge_job)
          fail FcarChuteConfigMissingMethodError.new(mod)
        end

        true
      end
      private_class_method :valid?
    end
  end
end
