module Uktt
  class Chapter
    attr_accessor :host, :version, :return_json, :chapter_id, :debug

    def initialize(chapter_id=nil, json=false, host=get_host, version=spec_version, debug=false)
      @host = host
      @version = version
      @chapter_id = chapter_id
      @return_json = json
      @debug = debug
    end

    def retrieve
      resource = "#{CHAPTER}/#{@chapter_id}.json"
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end

    def retrieve_all
      resource = "#{CHAPTER}.json"
      Uktt::Http.new(@host, @version, @debug).retrieve_all(resource, @return_json)
    end
  end
end
