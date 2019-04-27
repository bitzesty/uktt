module Uktt
  # A Chapter object for dealing with an API resource
  class Chapter
    attr_accessor :host, :version, :return_json, :chapter_id, :debug

    def initialize(chapter_id = nil,
                   json = false,
                   host = Uktt::Http.api_host,
                   version = Uktt::Http.spec_version,
                   debug = false)
      @host = host
      @version = version
      @chapter_id = chapter_id
      @return_json = json
      @debug = debug
    end

    def retrieve
      fetch "#{CHAPTER}/#{@chapter_id}.json"
    end

    def retrieve_all
      fetch "#{CHAPTER}.json"
    end

    def goods_nomenclatures
      fetch "#{GOODS_NOMENCLATURE}/chapter/#{@chapter_id}.json"
    end

    def changes
      fetch "#{CHAPTER}/#{@chapter_id}/changes.json"
    end

    def note
      fetch "#{CHAPTER}/#{@chapter_id}/chapter_note.json"
    end

    private

    def fetch(resource)
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
