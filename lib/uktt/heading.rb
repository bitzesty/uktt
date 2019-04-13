module Uktt
  class Heading
    attr_accessor :host, :version, :return_json, :heading_id

    def initialize(heading_id, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @heading_id = heading_id
      @return_json = json
    end

    def retrieve
      resource = "#{HEADING}/#{@heading_id}.json"
      Uktt::Http.new(@host, @version).retrieve(resource, @return_json)
    end
  end
end
