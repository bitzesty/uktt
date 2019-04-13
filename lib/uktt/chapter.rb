module Uktt
  class Chapter
    attr_accessor :host, :version, :return_json, :chapter_id

    def initialize(chapter_id=nil, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @chapter_id = chapter_id
      @return_json = json
    end

    def retrieve
      resource = "#{CHAPTER}/#{@chapter_id}.json"
      Uktt::Http.new(@host, @version).retrieve(resource, @return_json)
    end

    def retrieve_all
      resource = "#{CHAPTER}.json"
      Uktt::Http.new(@host, @version).retrieve_all(resource, @return_json)
    end
  end
end
