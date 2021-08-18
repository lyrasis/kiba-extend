# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Copy do
  describe 'Field' do
    rows = [
      %w[id name sex],
      [1, 'Weddy', 'm'],
      [2, 'Kernel', 'f']
    ]

    before do
      generate_csv(rows)
    end
    it 'copies value of field to specified new field' do
      expected = [
        { id: '1', name: 'Weddy', sex: 'm', gender: 'm' },
        { id: '2', name: 'Kernel', sex: 'f', gender: 'f' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Copy::Field,
                           xformopt: { from: :sex, to: :gender })
      expect(result).to eq(expected)
    end
  end
end
