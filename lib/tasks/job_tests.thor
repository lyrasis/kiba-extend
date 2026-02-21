# frozen_string_literal: true

require "thor"

# Commands to run/manage job tests
class JobTests < Thor
  desc "suite", "Run all job tests"
  option :dir, type: :string, aliases: "-d"
  def suite
    if options[:dir]
      Kiba::Extend::JobTest::SuiteRunner.new(options[:dir]).call
    else
      Kiba::Extend::JobTest::SuiteRunner.new.call
    end
  end
end
