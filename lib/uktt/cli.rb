require 'thor'
require 'uktt'

module Uktt
  # Implemets a CLI using Thor
  class CLI < Thor
    class_option :host,
                 aliases: ['-h', '--host'],
                 type: :string,
                 desc: "Use specified API host, otherwise `#{API_HOST_LOCAL}`",
                 banner: 'http://localhost:3002'
    class_option :version,
                 aliases: ['-a', '--api-version'],
                 type: :string,
                 desc: 'Request a specific API version, otherwise `v1`',
                 banner: 'v1'
    class_option :debug,
                 aliases: ['-d', '--debug'],
                 type: :boolean,
                 desc: 'Show request and response headers, otherwise not shown',
                 banner: true
    class_option :format,
                 aliases: ['-j', '--json'],
                 type: :boolean,
                 desc: 'Request JSON response, otherwise OpenStruct',
                 banner: true
    class_option :prod,
                 aliases: ['-p', '--production'],
                 type: :string,
                 desc: "Use production API host, otherwise `#{API_HOST_LOCAL}`",
                 banner: true
    class_option :goods, aliases: ['-g', '--goods'],
                 type: :string,
                 desc: 'Retrieve goods nomenclatures in this object',
                 banner: false
    class_option :note, aliases: ['-n', '--note'],
                 type: :string,
                 desc: 'Retrieve a note for this object',
                 banner: false
    class_option :changes, aliases: ['-c', '--changes'],
                 type: :string,
                 desc: 'Retrieve changes for this object',
                 banner: false

    desc 'section', 'Retrieves a section'
    def section(section_id)
      if options[:goods] && options[:version] != 'v2'
        puts 'V2 is required. Use `-a v2`'
        return
      elsif options[:changes]
        puts 'Option not supported for this object'
        return
      end

      uktt = Uktt::Section.new(options.merge(host: host, section_id: section_id))
      puts uktt.send(action)
    end

    desc 'sections', 'Retrieves all sections'
    def sections
      puts Uktt::Section.new(options.merge(host: host)).retrieve_all
    end

    desc 'chapter', 'Retrieves a chapter'
    def chapter(chapter_id)
      if options[:goods] && options[:version] != 'v2'
        puts 'V2 is required. Use `-a v2`'
        return
      end
      
      uktt = Uktt::Chapter.new(options.merge(host: host, chapter_id: chapter_id))
      puts uktt.send(action)
    end

    desc 'chapters', 'Retrieves all chapters'
    def chapters
      puts Uktt::Chapter.new(options.merge(host: host)).retrieve_all
    end

    desc 'heading', 'Retrieves a heading'
    def heading(heading_id)
      if options[:goods] && options[:version] != 'v2'
        puts 'V2 is required. Use `-a v2`'
        return
      elsif options[:note]
        puts 'Option not supported for this object'
        return
      end
      
      uktt = Uktt::Heading.new(options.merge(host: host, heading_id: heading_id))
      puts uktt.send(action)
    end

    desc 'commodity', 'Retrieves a commodity'
    def commodity(commodity_id)
      if options[:goods] || options[:note]
        puts 'Option not supported for this object'
        return
      end
      
      puts Uktt::Commodity.new(options.merge(host: host, commodity_id: commodity_id)).send(action)
    end

    desc 'monetary_exchange_rates', 'Retrieves monetary exchange rates'
    def monetary_exchange_rates
      puts Uktt::MonetaryExchangeRate.new(options.merge(host: host)).retrieve_all
    end

    desc 'pdf', 'Makes a PDF of a chapter'
    method_option :filepath, aliases: ['-f', '--filepath'],
                             type: :string,
                             desc: 'Save PDF to path and name, otherwise saves in `pwd`',
                             banner: '`pwd`'
    def pdf(chapter_id)
      puts "Making a PDF for Chapter #{chapter_id}"
      start_time = Time.now
      puts "Finished #{Uktt::Pdf.new(options.merge(chapter_id: chapter_id)).make_chapter} in #{Time.now - start_time}"
    end

    desc 'test', 'Runs API specs'
    def test
      host, version, _json, _debug, _filepath = handle_class_options(options)
      ver = version ? "VER=#{version} " : ''
      prod = host == API_HOST_PROD ? 'PROD=true ' : ''
      puts `#{ver}#{prod}bundle exec rspec ./spec/uktt_api_spec.rb`
    end

    desc 'info', 'Prints help for `uktt`'
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
          options[:debug] || false,
          options[:filepath] || nil,
          options[:goods] || false,
          options[:note] || false,
          options[:changes] || false,
        ]
      end

      def action
        if options[:goods]
          return :goods_nomenclatures
        elsif options[:note]
          return :note
        elsif options[:changes]
          return :changes
        else
          return :retrieve
        end
      end

      def host
        return ENV['HOST'] if ENV['HOST']

        options[:prod] ? API_HOST_PROD : Uktt::Http.api_host
      end
    end
  end
end
