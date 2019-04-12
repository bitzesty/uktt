module Uktt
  class Chapter

    def initialize(chapter_id=nil, json=false, host=nil, version=nil)
      @host = host
      @version = version
      @chapter_id = chapter_id
      @return_json = json
    end

    def retrieve
      Uktt::Http.new(@host, @version).retrieve("#{CHAPTER}/#{@chapter_id}.json", @return_json)
    end

    def retrieve_all
      Uktt::Http.new(@host, @version).retrieve_all("#{CHAPTER}.json", @return_json)
    end
  end
end
