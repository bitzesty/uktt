module Uktt
  class Section

    def initialize(section_id=nil, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @section_id = section_id
      @return_json = json
    end

    def retrieve
      Uktt::Http.new(@host, @version).retrieve("#{SECTION}/#{@section_id}.json", @return_json)
    end

    def retrieve_all
      Uktt::Http.new(@host, @version).retrieve_all("#{SECTION}.json", @return_json)
    end
  end
end
