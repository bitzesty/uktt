module Uktt
  # A MonetaryExchangeRate object for dealing with an API resource
  class MonetaryExchangeRate
    attr_accessor :host, :version, :return_json, :section_id, :debug

    def initialize(opts = {})
      @monetary_exchange_rate_id = opts[:monetary_exchange_rate_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def retrieve_all
      fetch "#{M_X_RATE}.json"
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
