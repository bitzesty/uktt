module Uktt
  class Commodity
    attr_accessor :host, :version, :return_json, :commodity_id, :debug

    def initialize(commodity_id, json=false, host=nil, version=nil, debug=false)
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
