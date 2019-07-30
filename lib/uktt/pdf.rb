require 'uktt/export_chapter_pdf'
require 'uktt/export_cover_pdf'

module Uktt
  # An object for producing PDF files of individual chapters in the Tariff
  class Pdf
    attr_accessor :chapter_id, :config

    def initialize(opts = {})
      @chapter_id = opts[:chapter_id] || nil
      @filepath = opts[:filepath] || "#{Dir.pwd}/#{@chapter_id || 'cover'}.pdf"
      @currency = opts[:currency] || 'EURO'
      Uktt.configure(opts)
      @config = Uktt.config
    end

    def make_chapter
      pdf = ExportChapterPdf.new(@config.merge(chapter_id: @chapter_id))
      pdf.save_as(@filepath)
      @filepath
    end

    def config=(new_opts = {})
      merged_opts = Uktt.config.merge(new_opts)
      Uktt.configure merged_opts
      @chapter_id = merged_opts[:chapter_id] || @chapter_id
      @filepath = merged_opts[:filepath] || @filepath
      @currency = merged_opts[:currency] || @currency
      @config = Uktt.config
    end

    def make_cover
      pdf = ExportCoverPdf.new
      pdf.save_as(@filepath)
      @filepath
    end
  end
end
