module Uktt
  class Heading

    def initialize(heading_id, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @heading_id = heading_id
      @return_json = json
    end

    def retrieve
      Uktt::Http.new(@host, @version).retrieve("#{HEADING}/#{@heading_id}.json", @return_json)
    end
  end
end
