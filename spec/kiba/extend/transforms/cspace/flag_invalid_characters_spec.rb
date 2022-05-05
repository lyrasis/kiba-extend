# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Cspace::FlagInvalidCharacters do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }


  before do
    @old = Cspace.const_get('BRUTEFORCE')
    Cspace.const_set('BRUTEFORCE', {})
  end
  after do
    Cspace.const_set('BRUTEFORCE', @old)
  end

  let(:input) do
    [
      {subject: 'Iași, Romania'},
      {subject: 'Iasi, Romania'}
    ]
  end

  let(:expected) do
    [
      { subject: 'Iași, Romania', flag: 'Ia%INVCHAR%i, Romania' },
      { subject: 'Iasi, Romania', flag: nil }
    ]
  end
  
  let(:transforms) do
    Kiba.job_segment do
      transform Cspace::FlagInvalidCharacters, check: :subject, flag: :flag
    end
  end
  
  it 'adds column containing field value with invalid chars replaced with ?' do
    expect(result).to eq(expected)
  end
end
