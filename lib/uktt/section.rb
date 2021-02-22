module Uktt
  # A Section object for dealing with an API resource
  class Section
    attr_accessor :config, :section_id

    def initialize(opts = {})
      @section_id = opts[:section_id] || nil
      Uktt.configure(opts.transform_keys(&:to_sym))
      @config = Uktt.config
    end

    def retrieve
      return '@section_id cannot be nil' if @section_id.nil?

      fetch "#{SECTION}/#{@section_id}.json"
    end

    def retrieve_all
      fetch "#{SECTION}.json"
    end

    def goods_nomenclatures
      return '@section_id cannot be nil' if @section_id.nil?

      fetch "#{GOODS_NOMENCLATURE}/section/#{@section_id}.json"
    end

    def note
      return '@section_id cannot be nil' if @section_id.nil?

      fetch "#{SECTION}/#{@section_id}/section_note.json"
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @section_id = merged_opts[:section_id] || @section_id
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
