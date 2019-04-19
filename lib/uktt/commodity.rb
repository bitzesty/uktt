module Uktt
  # A Commodity object for dealing with an API resource
  class Commodity
    attr_accessor :host, :version, :return_json, :commodity_id, :debug

    def initialize(commodity_id,
                   json = false,
                   host = api_host,
                   version = spec_version,
                   debug = false)
      @host = host
      @version = version
      @commodity_id = commodity_id
      @return_json = json
      @debug = debug
    end

    def retrieve
      resource = "#{COMMODITY}/#{@commodity_id}.json"
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
