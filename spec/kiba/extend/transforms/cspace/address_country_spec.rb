# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Cspace::AddressCountry do
  # let(:accumulator){ [] }
  # let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  # let(:result){ test_job.accumulator }

  # let(:input){ [{name: 'Weddy1'}] }
  # let(:expected){ [{ name: 'Weddy1', sid: 'Weddy13761760099' }] }
  # let(:transforms) do
  #   Kiba.job_segment do
  #     transform Cspace::ConvertToID, source: :name, target: :sid
  #   end
  # end

  let(:transform){ Cspace::AddressCountry.new }
  let(:result){ transform.process(row) }

  context 'when existing value is supported' do
    let(:row){ {addresscountry: 'Viet Nam'} }
    let(:expected){ {addresscountry: 'VN'} }
    it 'inserts CS shortID of given source into target' do
      expect(result).to eq(expected)
    end
  end

  context 'when existing value is supported' do
    let(:row){ {addresscountry: 'Vietnam'} }
    it 'inserts CS shortID of given source into target' do
      msg = "Cannot find code for addresscountry value: Vietnam"
      expect(transform).to receive(:warn).with(msg)
      transform.process(row)
    end
  end
end
