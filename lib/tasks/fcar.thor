# frozen_string_literal: true

unless Kiba::Extend::Fcar.chute.empty?
  class Fcar < Thor
    desc "chute", "display entire FCAR chute for project"
    def chute
      puts Kiba::Extend::Command::Fcar::Chute.call
    end

    desc "processes", "display active FCAR processes for project"
    def processes
      Kiba::Extend::Fcar.processes
        .each { |process| puts process }
    end
  end
end
