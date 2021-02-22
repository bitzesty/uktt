module Uktt
  # A Chapter object for dealing with an API resource
  class Heading
    attr_accessor :config, :heading_id, :response

    def initialize(opts = {})
      @heading_id = opts[:heading_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
      @response = nil
    end

    def retrieve
      return '@chapter_id cannot be nil' if @heading_id.nil?

      fetch "#{HEADING}/#{@heading_id}.json"
    end

    def goods_nomenclatures
      return '@chapter_id cannot be nil' if @heading_id.nil?

      fetch "#{GOODS_NOMENCLATURE}/heading/#{@heading_id}.json"
    end

    def note
      'a heading cannot have a note'
    end

    def changes
      return '@chapter_id cannot be nil' if @heading_id.nil?

      fetch "#{HEADING}/#{@heading_id}/changes.json"
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @heading_id = merged_opts[:heading_id] || @heading_id
      @config = Uktt.config
    end

    def find(id)
      return '@response is nil, run #retrieve first' unless @response
  
      response = @response.included.select do |obj|
        obj.id === id || obj.type === id
      end
      response.length == 1 ? response.first : response
    end

    private

    def fetch(resource)
      @response = Uktt::Http.new(
        @config[:host], 
        @config[:version], 
        @config[:debug])
      .retrieve(resource, 
        @config[:format])
    end
  end
end
