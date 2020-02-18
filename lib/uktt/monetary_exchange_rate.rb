module Uktt
  # A MonetaryExchangeRate object for dealing with an API resource
  class MonetaryExchangeRate
    attr_accessor :monetary_exchange_rate_id, :config, :response

    def initialize(opts = {})
      @monetary_exchange_rate_id = opts[:monetary_exchange_rate_id] || nil
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def retrieve_all
      fetch "#{M_X_RATE}.json"
    end

    def latest(currency)
      retrieve_all unless @response

      @response.select{ |obj| obj.child_monetary_unit_code == currency.upcase }
               .sort_by(&:validity_start_date)
               .last
               .exchange_rate
               .to_f
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @monetary_exchange_rate_id = merged_opts[:monetary_exchange_rate_id] || @monetary_exchange_rate_id
      @config = Uktt.config
    end

    private

    def fetch(resource)
      @response = Uktt::Http.new(
        @config[:host],
        @config[:version],
        @config[:debug]
      ).retrieve(
        resource,
        @config[:return_json]
      )

      @response = @response.data if @config[:version] == 'v2'

      @response
    end
  end
end
