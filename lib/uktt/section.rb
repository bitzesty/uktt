module Uktt
  class Section
    attr_accessor :host, :version, :return_json, :section_id, :debug

    def initialize(section_id=nil, json=false, host=nil, version=nil, debug=false)
      @host = host
      @version = version
      @section_id = section_id
      @return_json = json
      @debug = debug
    end

    def retrieve
      resource = "#{SECTION}/#{@section_id}.json"
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end

    def retrieve_all
      resource = "#{SECTION}.json"
      Uktt::Http.new(@host, @version, @debug).retrieve_all(resource, @return_json)
    end
  end
end
