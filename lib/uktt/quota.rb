module Uktt
  # A Quota object for dealing with an API resource
  class Quota
    attr_accessor :host, :version, :return_json, :obj_type, :debug

    def initialize(obj_type = nil,
                   json = false,
                   host = Uktt::Http.api_host,
                   version = Uktt::Http.spec_version,
                   debug = false)
      @host = host
      @version = version
      @obj_type = obj_type
      @return_json = json
      @debug = debug
    end

    def search(params)
      fetch "#{QUOTA}/search.json?#{URI.encode_www_form(params)}"
    end

    private

    def fetch(resource)
      Uktt::Http.new(@host, @version, @debug).retrieve(resource, @return_json)
    end
  end
end
