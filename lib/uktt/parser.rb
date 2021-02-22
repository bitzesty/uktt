require 'json'
require_relative 'parser/json_api'

module Uktt
  class Parser
    def initialize(body, format)
      @body = body
      @format = format
    end

    def parse
      return @body if json?
      return ostruct if ostruct?
      return json_api if json_api?

      raise ArgumentError, "Specified invalid format #{@format}"
    end

    private

    def json_api
      JsonApi.new(@body).parse
    end

    def ostruct
      JSON.parse(@body, object_class: OpenStruct)
    end

    def json?
      @format == 'json'
    end

    def ostruct?
      @format == 'ostruct'
    end

    def json_api?
      @format == 'jsonapi'
    end
  end
end
