module Uktt
  # A Quota object for dealing with an API resource
  class Quota
    attr_accessor :config

    def initialize(opts = {})
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def search(params)
      fetch "#{QUOTA}/search.json?#{URI.encode_www_form(params)}"
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
                     @config[:format])
    end
  end
end
