# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::SepDeprecator do
  subject(:util){ described_class.new(**params) }

  class Xform
  end

  describe '#call' do
    let(:result){ util.call }

    context 'with delim and no sep' do
      let(:xform){ instance_double('Xform') }
      let(:params){ {sep: nil, delim: '|', calledby: xform} }

      it 'returns expected' do
        expect(result.delim).to eq('|')
        expect(util).not_to receive(:warn)
      end
    end

    context 'with sep and no delim' do
      let(:warning) do
        "#{Kiba::Extend.warning_label}:\n  Xform: `sep` parameter will "\
          "be deprecated in a future release.\nTO FIX:\n  Change `sep` "\
          "to `delim`"
      end
      let(:xform){ instance_double('Xform') }
      let(:params){ {sep: '|', delim: nil, calledby: xform} }

      it 'returns expected' do
        allow(xform).to receive(:class).and_return('Xform')
        expect(util).to receive(:warn).with(warning)
        expect(result.delim).to eq('|')
      end
    end

    context 'with sep and delim' do
      let(:warning) do
        "#{Kiba::Extend.warning_label}:\n  Xform: `sep` and `delim` "\
          "parameters given. `delim` value used. `sep` value ignored. "\
          "`sep` will be deprecated in a future release.\n"\
          "TO FIX:\n  Remove `sep` param"
      end
      let(:xform){ instance_double('Xform') }
      let(:params){ {sep: ';', delim: '|', calledby: xform} }

      it 'returns expected' do
        allow(xform).to receive(:class).and_return('Xform')
        expect(util).to receive(:warn).with(warning)
        expect(result.delim).to eq('|')
      end
    end

    context 'without sep or delim' do
      let(:xform){ instance_double('Xform') }
      let(:params){ {sep: nil, delim: nil, calledby: xform} }

      it 'returns expected' do
        expect{result}.to raise_error(ArgumentError, "missing keyword: :delim")
      end
    end
  end
end
