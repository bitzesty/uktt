module Uktt
  class Section
    attr_accessor :host, :version, :return_json, :section_id

    def initialize(section_id=nil, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @section_id = section_id
      @return_json = json
    end

    def retrieve
      resource = "#{SECTION}/#{@section_id}.json"
      Uktt::Http.new(@host, @version).retrieve(resource, @return_json)
    end

    def retrieve_all
      resource = "#{SECTION}.json"
      Uktt::Http.new(@host, @version).retrieve_all(resource, @return_json)
    end
  end
end
