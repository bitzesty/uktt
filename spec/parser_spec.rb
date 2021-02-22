# frozen_string_literal: true

RSpec.describe Uktt::Parser do
  subject(:parser) { described_class.new(body, format) }

  let(:body) { read_file('commodity.json') }

  context 'when parsing to ostruct' do
    let(:format) { 'ostruct' }

    it 'returns valid OpenStruct' do
      expect(parser.parse).to be_a(OpenStruct)
    end
  end

  context 'when parsing to json' do
    let(:format) { 'json' }

    it 'returns valid raw json' do
      expect(parser.parse).to eq(body)
    end
  end

  context 'when parsing to jsonapi' do
    let(:format) { 'jsonapi' }
    let(:schema) { parse_file('schemas/commodity.json') }

    it 'returns valid jsonapi' do
      parsed = parser.parse
      valid = JSON::Validator.validate(schema, parsed)
      expect(valid).to be(true)
    end
  end

  context 'when parsing to an unknown format' do
    let(:format) { 'foo' }

    it 'propagates an error' do
      expect { parser.parse }.to raise_error(ArgumentError, 'Specified invalid format foo')
    end
  end
end
