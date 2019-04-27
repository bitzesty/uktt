module Uktt
  # A Section object for dealing with an API resource
  class Section
    attr_accessor :host, :version, :return_json, :section_id, :debug

    def initialize(section_id = nil,
                   json = false,
                   host = Uktt::Http.api_host,
                   version = Uktt::Http.spec_version,
                   debug = false)
      @host = host
      @version = version
      @section_id = section_id
      @return_json = json
      @debug = debug
    end

    def retrieve
      fetch "#{SECTION}/#{@section_id}.json"
    end

    def retrieve_all
      fetch "#{SECTION}.json"
    end

    def goods_nomenclatures
      fetch "#{GOODS_NOMENCLATURE}/section/#{@section_id}.json"
    end

    def note
      fetch "#{SECTION}/#{@section_id}/section_note.json"
    end

    private

    def fetch(resource)
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
