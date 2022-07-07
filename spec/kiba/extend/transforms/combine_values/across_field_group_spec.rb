# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::CombineValues::AcrossFieldGroup do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {fieldmap: fieldmap, sep: sep }}
  let(:sep){ '|' }
  let(:result){ input.map{ |row| xform.process(row) } }

  let(:input){ [{b: 'b', a: 'a'}] }
  let(:fieldmap){ {z: %i[a b]} }
  let(:expected){ [{z: 'a|b'}] }

  it 'uses redirect to do expected transform' do
    expect(result).to eq(expected)
  end
end

