module Uktt
  # A Commodity object for dealing with an API resource
  class Commodity
    attr_accessor :config, :commodity_id, :response

    def initialize(opts = {})
      @commodity_id = opts[:commodity_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
      @response = nil
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
      @commodity_id = merged_opts[:commodity_id] || @commodity_id
      @config = Uktt.config
    end
    
    def find(id)
      return '@response is nil, run #retrieve first' unless @response
  
      response = @response.included.select do |obj|
        obj.id === id || obj.type === id
      end
      response.length == 1 ? response.first : response
    end

    def find_in(arr)
      return '@response is nil, run #retrieve first' unless @response
  
      response = @response.included.select do |obj|
        arr.include?(obj.id)
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
