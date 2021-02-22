module Uktt
  # A Chapter object for dealing with an API resource
  class Chapter
    attr_accessor :config, :chapter_id

    def initialize(opts = {})
      @chapter_id = opts[:chapter_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def retrieve
      return '@chapter_id cannot be nil' if @chapter_id.nil?

      fetch "#{CHAPTER}/#{@chapter_id}.json"
    end

    def retrieve_all
      fetch "#{CHAPTER}.json"
    end

    def goods_nomenclatures
      return '@chapter_id cannot be nil' if @chapter_id.nil?

      fetch "#{GOODS_NOMENCLATURE}/chapter/#{@chapter_id}.json"
    end

    def changes
      return '@chapter_id cannot be nil' if @chapter_id.nil?

      fetch "#{CHAPTER}/#{@chapter_id}/changes.json"
    end

    def note
      return '@chapter_id cannot be nil' if @chapter_id.nil?

      fetch "#{CHAPTER}/#{@chapter_id}/chapter_note.json"
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @chapter_id = merged_opts[:chapter_id] || @chapter_id
      @config = Uktt.config
    end

    private

    def fetch(resource)
      Uktt::Http.new(@config[:host], 
                     @config[:version], 
                     @config[:debug])
      .retrieve(resource, 
                @config[:format])
    end
  end
end
