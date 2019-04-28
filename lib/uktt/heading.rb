module Uktt
  # A Chapter object for dealing with an API resource
  class Heading
    attr_accessor :config, :heading_id

    def initialize(opts = {})
      @heading_id = opts[:heading_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def retrieve
      return '@chapter_id cannot be nil' if @heading_id.nil?

      fetch "#{HEADING}/#{@heading_id}.json"
    end

    def goods_nomenclatures
      return '@chapter_id cannot be nil' if @heading_id.nil?

      fetch "#{GOODS_NOMENCLATURE}/heading/#{@heading_id}.json"
    end

    def changes
      return '@chapter_id cannot be nil' if @heading_id.nil?

      fetch "#{HEADING}/#{@heading_id}/changes.json"
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @config = Uktt.config
    end

    private

    def fetch(resource)
      Uktt::Http.new(@config[:host], 
                     @config[:version], 
                     @config[:debug])
      .retrieve(resource, 
                     @config[:return_json])
    end
  end
end
