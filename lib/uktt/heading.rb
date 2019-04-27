module Uktt
  # A Chapter object for dealing with an API resource
  class Heading
    attr_accessor :host, :version, :return_json, :heading_id, :debug

    def initialize(heading_id,
                   json = false,
                   host = Uktt::Http.api_host,
                   version = Uktt::Http.spec_version,
                   debug = false)
      @host = host
      @version = version
      @heading_id = heading_id
      @return_json = json
      @debug = debug
    end

    def retrieve
      fetch "#{HEADING}/#{@heading_id}.json"
    end

    def goods_nomenclatures
      fetch "#{GOODS_NOMENCLATURE}/heading/#{@heading_id}.json"
    end

    def changes
      fetch "#{HEADING}/#{@heading_id}/changes.json"
    end

    private

    def fetch(resource)
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
