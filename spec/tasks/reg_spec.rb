# frozen_string_literal: true

require 'spec_helper'
load 'lib/tasks/reg.thor'

RSpec.describe Reg do
  before(:context) do
    Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
    prepare_registry
  end

  context 'with tags' do
    it 'lists tags' do
      expected = "report\ntest\n"
      expect{ subject.tags }.to output(expected).to_stdout
    end
  end
end
