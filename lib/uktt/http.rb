require 'faraday'
require 'json'

module Uktt
  API_HOST_PROD = 'https://www.trade-tariff.service.gov.uk'.freeze
  API_HOST_LOCAL = 'http://localhost:3002'.freeze
  API_VERSION = 'v1'.freeze
  SECTION = '/sections'.freeze
  CHAPTER = '/chapters'.freeze
  HEADING = '/headings'.freeze
  COMMODITY = '/commodities'.freeze

  class Http
    def initialize(host=nil, version=nil)
      @host = host || API_HOST_LOCAL
      @version = version || API_VERSION
      @conn = Faraday.new(:url => @host) do |faraday|
        # faraday.response :logger                  # log requests and responses to $stdout
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    def retrieve(resource, return_json=false)
      response = @conn.get do |request|
        request.url([@version, resource].join('/'))
      end
      json = response.body
      return json if return_json

      OpenStruct.new(
        JSON.parse(
          json,
          symbolize_names: true
        )
      )
    end

    def retrieve_all(resource, return_json=false)
      response = @conn.get do |request|
        request.url([@version, resource].join('/'))
      end
      json = response.body
      return json if return_json

      JSON.parse(
        json,
        symbolize_names: true
      ).map do |hash|
        OpenStruct.new(hash)
      end
    end
  end
end
