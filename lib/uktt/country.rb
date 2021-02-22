module Uktt
  # A Commodity object for dealing with an API resource
  class Country
    attr_accessor :config, :response

    def initialize(opts = {})
      Uktt.configure(opts)
      @config = Uktt.config
      @response = nil
    end

    def retrieve
      fetch "#{GEOGRAPHICAL_AREAS}/countries"
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @config = Uktt.config
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
