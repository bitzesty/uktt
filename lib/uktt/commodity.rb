module Uktt
  class Commodity

    def initialize(commodity_id, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @commodity_id = commodity_id
      @return_json = json
    end

    def retrieve
      Uktt::Http.new(@host, @version).retrieve("#{COMMODITY}/#{@commodity_id}.json", @return_json)
    end
  end
end
