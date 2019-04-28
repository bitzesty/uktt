module Uktt
  # A Commodity object for dealing with an API resource
  class Commodity
    attr_accessor :config, :commodity_id

    def initialize(opts = {})
      @commodity_id = opts[:commodity_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def retrieve
      return '@commodity_id cannot be nil' if @commodity_id.nil?

      fetch "#{COMMODITY}/#{@commodity_id}.json"
    end

    def changes
      return '@commodity_id cannot be nil' if @commodity_id.nil?

      fetch "#{COMMODITY}/#{@commodity_id}/changes.json"
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
