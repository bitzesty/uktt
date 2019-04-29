require 'faraday'
require 'json'

module Uktt
  # An object for handling network requests
  class Http
    def initialize(host = nil, version = nil, debug = false)
      @host = host || API_HOST_LOCAL
      @version = version || API_VERSION
      @conn = Faraday.new(url: @host) do |faraday|
        faraday.response(:logger) if debug
        faraday.adapter Faraday.default_adapter
      end
    end

    def retrieve(resource, return_json = false)
      json = @conn.get do |request|
        request.url([@version, resource].join('/'))
      end.body
      return json if return_json

      JSON.parse(json, object_class: OpenStruct)
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
