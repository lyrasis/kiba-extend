# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Append::ConvertedValueAndUnit do  
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      { value: nil, unit: nil },
      { value: '1.5', unit: nil },
      { value: '1.5', unit: 'inches' },
      { value: '2', unit: 'feet' },
      { value: '2', unit: 'pounds' },
      { value: '2', unit: 'ounces' }
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Append::ConvertedValueAndUnit,
        value: :value,
        unit: :unit,
        delim: '|',
        places: 2
    end
  end

  let(:expected) do
    [
      { value: nil, unit: nil },
      { value: '1.5', unit: nil },
      {value: '1.5|3.81', unit: 'inches|centimeters'},
      {value: '2|0.61', unit: 'feet|meters'},
      {value: '2|0.91', unit: 'pounds|kilograms'},
      {value: '2|56.7', unit: 'ounces|grams'},
    ]
  end
  
  it 'adds converted value and unit' do
    expect(result).to eq(expected)
  end

  context 'when unit type is unknown' do
    let(:input) do
      [
        { value: '1', unit: 'step' }
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: '|',
          places: 2
      end
    end

    let(:expected) do
      [
        { value: '1', unit: 'step' }
      ]
    end
    
    it 'returns original row' do
      expect(result).to eq(expected)
    end

    it 'prints warning to STDOUT' do
      msg = %Q[KIBA WARNING: Unknown unit type "step" in "unit" field. Configure types parameter\n]
      expect{ result }.to output(msg).to_stdout
    end
  end

  context 'when unit conversion is unknown' do
    let(:input) do
      [
        { value: '1', unit: 'step' }
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: '|',
          places: 2,
          types: {'step' => Measured::Length}
      end
    end

    let(:expected) do
      [
        { value: '1', unit: 'step' }
      ]
    end
    
    it 'returns original row' do
      expect(result).to eq(expected)
    end

    it 'prints warning to STDOUT' do
      msg = %Q[KIBA WARNING: Unknown conversion to perform for "step" in "unit" field. Configure conversions parameter\n]
      expect{ result }.to output(msg).to_stdout
    end
  end

  context 'when unit conversion amount not configured' do
    let(:input) do
      [
        { value: '1', unit: 'step' }
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: '|',
          places: 2,
          types: {'step' => Measured::Length},
          conversions: {'step' => 'feet'}
      end
    end

    let(:expected) do
      [
        { value: '1', unit: 'step' }
      ]
    end
    
    it 'returns original row' do
      expect(result).to eq(expected)
    end

    it 'prints warning to STDOUT' do
      msg = %Q[KIBA WARNING: No known conversion method for "step" to "feet" in "unit" field. Configure conversion_amounts parameter\n]
      expect{ result }.to output(msg).to_stdout
    end
  end

  context 'when custom unit conversion configured' do
    let(:input) do
      [
        { value: '1', unit: 'steps' }
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: '|',
          places: 2,
          types: {'steps' => Measured::Length},
          conversions: {'steps' => 'feet'},
          conversion_amounts: {
            steps: [2.5, :feet]
          }
      end
    end

    let(:expected) do
      [
        { value: '1|2.5', unit: 'steps|feet' }
      ]
    end

    
    it 'adds value and unit' do
      expect(result).to eq(expected)
    end
  end
end
