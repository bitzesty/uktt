require 'faraday'
require 'faraday_middleware'

module Uktt
  # An object for handling network requests
  class Http
    def initialize(host = nil, version = nil, debug = false, conn = nil)
      @host = host || API_HOST_LOCAL
      @version = version || API_VERSION

      @conn = conn || Faraday.new(url: @host) do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.response(:logger) if debug
        faraday.adapter Faraday.default_adapter
      end
    end

    def retrieve(resource, format = 'ostruct')
      full_url = File.join(@host, 'api', @version, resource)
      headers  = { 'Content-Type' => 'application/json' }
      response = @conn.get(full_url, {}, headers)

      Parser.new(response.body, format).parse
    end

    class << self
      def use_production
        !ENV['PROD'].nil? && ENV['PROD'].casecmp('true').zero?
      end

      def spec_version
        return @version unless @version.nil?

        ENV['VER'] ? ENV['VER'].to_s : 'v1'
      end

      def api_host
        return ENV['HOST'] if ENV['HOST']

        use_production ? Uktt::API_HOST_PROD : Uktt::API_HOST_LOCAL
      end
    end
  end
end
