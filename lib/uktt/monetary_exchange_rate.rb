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

      case @config[:version]
      when 'v1'
        @response.select{ |obj| obj.child_monetary_unit_code == currency.upcase }
                 .sort_by(&:validity_start_date)
                 .last.exchange_rate.to_f
      when 'v2'
        @response.data.select{ |obj| obj.attributes.child_monetary_unit_code == currency.upcase }
                 .sort_by{ |obj| obj.attributes.validity_start_date }
                 .last.attributes.exchange_rate.to_f
      else
        raise StandardError.new "`#{@opts[:version]}` is not a supported API version. Supported API versions are: v1 and v2"
      end
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
        @config[:format]
      )
    end
  end
end
