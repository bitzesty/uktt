require 'uktt/export_chapter_pdf'

module Uktt
  # An object for producing PDF files of individual chapters in the Tariff
  class Pdf
    def initialize(chapter_id = nil,
                   _json = false,
                   host = nil,
                   version = nil,
                   debug = false,
                   filepath = nil)
      @host = host
      @version = version
      @chapter_id = chapter_id
      @return_json = false # use Openstruct/ruby hash
      @debug = debug
      @filepath = filepath || "#{Dir.pwd}/#{@chapter_id}.pdf"
    end

    def make_chapter
      pdf = ExportChapterPdf.new(@chapter_id,
                                 @return_json,
                                 @host,
                                 @version, @debug)
      pdf.save_as(@filepath)
      @filepath
    end
  end
end
