# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'ActionArgumentable' do
  describe '#new' do
    let(:result){ described_class.new(**params) }

    context 'with valid action value' do
      let(:params){ addparams.merge({action: :keep}) }

      it 'does not raise error' do
        expect{ result }.not_to raise_error
      end
    end

    context 'with invalid action value' do
      let(:params){ addparams.merge({action: :select}) }

      it 'raises error' do
        expect{ result }.to raise_error(Kiba::Extend::InvalidActionError)
      end
    end
  end
end

RSpec.describe Kiba::Extend::Transforms::FilterRows::AllFieldsPopulated do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {fields: %i[a b]} }
  end
end

RSpec.describe Kiba::Extend::Transforms::FilterRows::AnyFieldsPopulated do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {fields: %i[a b]} }
  end
end

RSpec.describe Kiba::Extend::Transforms::FilterRows::FieldEqualTo do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {field: :a, value: 'foo'} }
  end
end

RSpec.describe Kiba::Extend::Transforms::FilterRows::FieldMatchRegexp do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {field: :a, match: '^foo'} }
  end
end

RSpec.describe Kiba::Extend::Transforms::FilterRows::FieldPopulated do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {field: :a} }
  end
end

RSpec.describe Kiba::Extend::Transforms::FilterRows::WithLambda do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {lambda: ->(row){ row }} }
  end
end

RSpec.describe Kiba::Extend::Transforms::Marc::FilterRecords::ById do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {id_values: ['a', 'b']} }
  end
end

RSpec.describe Kiba::Extend::Transforms::Marc::FilterRecords::WithLambda do
  it_behaves_like 'ActionArgumentable' do
    let(:addparams){ {lambda: ->(rec){ rec }} }
  end
end
