require 'thor'
require 'uktt'

module Uktt
  class CLI < Thor

    class_option :version, aliases: ['-a', '--api-version'], type: :string, desc: 'Request a specific API version, otherwise `v1`', banner: 'v1'
    class_option :host,    aliases: ['-h', '--host'], type: :string, desc: "Use specified API host, otherwise `#{API_HOST_LOCAL}`", banner: 'http://localhost:3002'
    class_option :json,    aliases: ['-j', '--json'], type: :boolean, desc: 'Request JSON response, otherwise OpenStruct', banner: true
    class_option :prod,    aliases: ['-p', '--production'], type: :string, desc: "Use production API host, otherwise `#{API_HOST_LOCAL}`", banner: true
    class_option :debug,   aliases: ['-d', '--debug'], type: :boolean, desc: "Show request and response headers, otherwise they are not shown", banner: true

    desc 'section', 'Retrieves a section'
    def section(section_id)
      host, version, json, debug = handle_class_options(options)
      puts Uktt::Section.new(section_id, json, host, version, debug).retrieve
    end

    desc 'sections', 'Retrieves all sections'
    def sections
      host, version, json, debug = handle_class_options(options)
      puts Uktt::Section.new(nil, json, host, version, debug).retrieve_all
    end

    desc 'chapter', 'Retrieves a chapter'
    def chapter(chapter_id)
      host, version, json, debug = handle_class_options(options)
      puts Uktt::Chapter.new(chapter_id, json, host, version, debug).retrieve
    end

    desc 'chapters', 'Retrieves all chapters'
    def chapters
      host, version, json, debug = handle_class_options(options)
      puts Uktt::Chapter.new(nil, json, host, version, debug).retrieve_all
    end

    desc 'heading', 'Retrieves a heading'
    def heading(heading_id)
      host, version, json, debug = handle_class_options(options)
      puts Uktt::Heading.new(heading_id, json, host, version, debug).retrieve
    end

    desc 'commodity', 'Retrieves a commodity'
    def commodity(commodity_id)
      host, version, json, debug = handle_class_options(options)
      puts Uktt::Commodity.new(commodity_id, json, host, version, debug).retrieve
    end

    desc 'info', 'Prints help for Uktt'
    method_option :version, aliases: ['-v', '--version']
    def info
      if options[:version]
        puts Uktt::VERSION
      elsif ARGV
        help
      else
        help
      end
    end
    default_task :info

    no_commands do
      def handle_class_options(options)
        [
          options[:host] || (options[:prod] ? API_HOST_PROD : API_HOST_LOCAL),
          options[:api_version] || 'v1',
          options[:json] || false,
          options[:debug] || false
        ]
      end
    end
  end
end
