require 'uktt/version'
require 'uktt/http'
require 'uktt/section'
require 'uktt/chapter'
require 'uktt/heading'
require 'uktt/country'
require 'uktt/commodity'
require 'uktt/monetary_exchange_rate'
require 'uktt/quota'
require 'uktt/pdf'

require 'yaml'
require 'psych'

module Uktt
  API_HOST_PROD =       'https://www.trade-tariff.service.gov.uk/api'.freeze
  API_HOST_LOCAL =      'http://localhost:3002/api'.freeze
  API_VERSION        = 'v1'.freeze
  CHAPTER            = 'chapters'.freeze
  COMMODITY          = 'commodities'.freeze
  GEOGRAPHICAL_AREAS = 'geographical_areas'.freeze
  GOODS_NOMENCLATURE = 'goods_nomenclatures'.freeze
  HEADING            = 'headings'.freeze
  M_X_RATE           = 'monetary_exchange_rates'.freeze
  PARENT_CURRENCY    = 'EUR'.freeze
  QUOTA              = 'quotas'.freeze
  SECTION            = 'sections'.freeze

  class Error < StandardError; end

  # Configuration defaults
  @config = {
              host: Uktt::Http.api_host, 
              version: Uktt::Http.spec_version, 
              debug: false,
              return_json: false,
              currency: PARENT_CURRENCY
            }

  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym}
  end

  # Configure through yaml file
  def self.configure_with(path_to_yaml_file)
    begin
      config = YAML::load(IO.read(path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end

    configure(config)
  end

  def self.config
    @config
  end
end
