require 'uktt'

RSpec.describe Uktt::Http do
  subject(:client) { described_class.new(host, version, debug, conn) }

  let(:version) { 'v2' }
  let(:debug) { false }
  let(:conn) { double }
  let(:response) { double }
  let(:parser) { double(parse: {}) }
  let(:host) { 'http://localhost' }

  describe '#retrieve' do
    before do
      allow(conn).to receive(:get).and_return(response)
      allow(response).to receive(:body).and_return('{}')
      allow(Uktt::Parser).to receive(:new).and_return(parser)
    end

    let(:expected_headers) { { 'Content-Type' => 'application/json' } }
    let(:expected_body) { {} } 


    it 'passes the body and format to the Parser' do
      client.retrieve('commodities/1234567890')

      expect(Uktt::Parser).to have_received(:new).with('{}', 'ostruct')
    end


    context 'when the host includes xi in the path' do
      let(:host) { 'http://localhost/xi' }
      let(:expected_url)  { 'http://localhost/xi/api/v2/commodities/1234567890' } 

      it 'uses the correct full url' do
        client.retrieve('commodities/1234567890')

        expect(conn).to have_received(:get).with(expected_url, expected_body, expected_headers)
      end
    end

    context 'when the host does not include xi in the path' do
      let(:host) { 'http://localhost' }
      let(:expected_url)  { 'http://localhost/api/v2/commodities/1234567890' } 

      it 'uses the correct full url' do
        client.retrieve('commodities/1234567890')

        expect(conn).to have_received(:get).with(expected_url, expected_body, expected_headers)
      end
    end
  end
end
