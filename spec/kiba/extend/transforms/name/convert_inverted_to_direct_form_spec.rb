# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Name::ConvertInvertedToDirectForm do
  let(:klass){ Name::ConvertInvertedToDirectForm.new(source: :iname, target: :direct) }

  let(:rows) do
    [
      {iname: 'Smith, Robert'},
      {iname: 'Smith, Robert J.'},
      {iname: 'Smith-Jones, Robert J.'},
      {iname: 'Smith, Robert James'},
      {iname: 'Smith, R. James'},
      {iname: 'Smith, Robert (Bob)'},
      {iname: 'Smith, Robert James (Bob)'},
      {iname: 'Smith, R. J.'},
      {iname: 'Smith, R.J.'},
      {iname: 'Smith, R J'},
      {iname: 'Smith, RJ'},
      {iname: 'Smith, RJR'},
      {iname: 'Smith, RJRR'},
      {iname: 'Smith, R.'},
      {iname: 'Smith'},
      {iname: 'Smith, Robert, Jr.'},
      {iname: 'Smith, R.J., Sr.'},
      {iname: 'Smith, R. J., Sr.'},
      {iname: 'R.J. Smith & Co.'},
      {iname: 'Smith, James, Robert & Co.'},
      {iname: 'Robert "Bob" Smith'},
      {iname: ''},
      {iname: nil},
      {foo: 'bar'}
    ]
  end

  let(:expected) do
    [
      {iname: 'Smith, Robert', direct: 'Robert Smith', firstname: 'Robert', lastname: 'Smith', middlename: nil, suffix: nil},
      {iname: 'Smith, Robert J.', direct: 'Robert J. Smith', firstname: 'Robert', lastname: 'Smith', middlename: 'J.', suffix: nil},
      {iname: 'Smith-Jones, Robert J.', direct: 'Robert J. Smith-Jones', firstname: 'Robert', lastname: 'Smith-Jones', middlename: 'J.', suffix: nil},
      {iname: 'Smith, Robert James', direct: 'Robert James Smith', firstname: 'Robert', lastname: 'Smith', middlename: 'James', suffix: nil},
      {iname: 'Smith, R. James', direct: 'R. James Smith', firstname: 'R.', lastname: 'Smith', middlename: 'James', suffix: nil},
      {iname: 'Smith, Robert (Bob)', direct: 'Robert (Bob) Smith', firstname: 'Robert', lastname: 'Smith', middlename: '(Bob)', suffix: nil},
      {iname: 'Smith, Robert James (Bob)', direct: 'Robert James (Bob) Smith', firstname: 'Robert', lastname: 'Smith', middlename: 'James (Bob)', suffix: nil},
      {iname: 'Smith, R. J.', direct: 'R. J. Smith', firstname: 'R.', lastname: 'Smith', middlename: 'J.', suffix: nil},
      {iname: 'Smith, R.J.', direct: 'R. J. Smith', firstname: 'R.', lastname: 'Smith', middlename: 'J.', suffix: nil},
      {iname: 'Smith, R J', direct: 'R J Smith', firstname: 'R', lastname: 'Smith', middlename: 'J', suffix: nil},
      {iname: 'Smith, RJ', direct: 'R J Smith', firstname: 'R', lastname: 'Smith', middlename: 'J', suffix: nil},
      {iname: 'Smith, RJR', direct: 'R JR Smith', firstname: 'R', lastname: 'Smith', middlename: 'JR', suffix: nil},
      {iname: 'Smith, RJRR', direct: 'RJRR Smith', firstname: 'RJRR', lastname: 'Smith', middlename: nil, suffix: nil},
      {iname: 'Smith, R.', direct: 'R. Smith', firstname: 'R.', lastname: 'Smith', middlename: nil, suffix: nil},
      {iname: 'Smith', direct: 'Smith', firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {iname: 'Smith, Robert, Jr.', direct: 'Robert Smith, Jr.', firstname: 'Robert', lastname: 'Smith', middlename: nil, suffix: 'Jr.'},
      {iname: 'Smith, R.J., Sr.', direct: 'R. J. Smith, Sr.', firstname: 'R.', lastname: 'Smith', middlename: 'J.', suffix: 'Sr.'},
      {iname: 'Smith, R. J., Sr.', direct: 'R. J. Smith, Sr.', firstname: 'R.', lastname: 'Smith', middlename: 'J.', suffix: 'Sr.'},
      {iname: 'R.J. Smith & Co.', direct: 'R.J. Smith & Co.', firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {iname: 'Smith, James, Robert & Co.', direct: 'James Smith, Robert & Co.', firstname: 'James', lastname: 'Smith', middlename: nil, suffix: 'Robert & Co.'},
      {iname: 'Robert "Bob" Smith', direct: 'Robert "Bob" Smith', firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {iname: '', direct: '', firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {iname: nil, direct: nil, firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {foo: 'bar', direct: nil, firstname: nil, lastname: nil, middlename: nil, suffix: nil}

    ]
  end

  let(:result){ rows.map{ |row| klass.process(row) } }

  context 'with default settings' do
    it 'transforms as expected' do
      result.each{ |r| puts r }
      expect(result).to eq(expected)
    end
  end

  context 'with custom nameparts' do
    let(:klass){ Name::ConvertInvertedToDirectForm.new(source: :iname, target: :direct, nameparts: %i[f m l s]) }
    let(:row){ {iname: 'Smith, R.J., Sr.'} }
    let(:expected){ {iname: 'Smith, R.J., Sr.', direct: 'R. J. Smith, Sr.', f: 'R.', l: 'Smith', m: 'J.', s: 'Sr.'} }

    it 'transforms as expected' do
      puts expected
      expect(klass.process(row)).to eq(expected)
    end
  end

  context 'with keep_parts false' do
    let(:klass){ Name::ConvertInvertedToDirectForm.new(source: :iname, target: :direct, keep_parts: false) }
    let(:row){ {iname: 'Smith, R.J., Sr.'} }
    let(:expected){ {iname: 'Smith, R.J., Sr.', direct: 'R. J. Smith, Sr.'} }

    it 'transforms as expected' do
      puts expected
      expect(klass.process(row)).to eq(expected)
    end
  end
end

