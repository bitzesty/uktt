module Uktt
  # A Section object for dealing with an API resource
  class Section
    attr_accessor :host, :version, :return_json, :section_id, :debug

    def initialize(section_id = nil,
                   json = false,
                   host = api_host,
                   version = spec_version,
                   debug = false)
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
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
