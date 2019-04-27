module Uktt
  # A MonetaryExchangeRate object for dealing with an API resource
  class MonetaryExchangeRate
    attr_accessor :host, :version, :return_json, :section_id, :debug

    def initialize(section_id = nil,
                   json = false,
                   host = Uktt::Http.api_host,
                   version = Uktt::Http.spec_version,
                   debug = false)
      @host = host
      @version = version
      @section_id = section_id
      @return_json = json
      @debug = debug
    end

    def retrieve_all
      fetch "#{M_X_RATE}.json"
    end

    private

    def fetch(resource)
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
