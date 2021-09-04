# frozen_string_literal: true

require 'spec_helper'
load 'lib/tasks/reg.thor'

RSpec.describe Reg do
  before(:context){ prepare_registry }

  context 'with tags' do
    it 'lists tags' do
      expected = "report\ntest\n"
      expect{ subject.tags }.to output(expected).to_stdout
    end
  end
end
