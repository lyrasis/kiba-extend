# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Cspace::FlagInvalidCharacters do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }


  before do
    @old = Cspace.shady_characters.dup
    Cspace.redefine_singleton_method(:shady_characters){ {}.freeze }
  end
  after do
    hash = @old.dup.freeze
    Cspace.define_singleton_method(:shady_characters){ hash }
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
