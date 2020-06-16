require 'prawn'
require 'prawn/table'
require 'nokogiri'

# A class to produce a PDF for a single chapter
class ExportChapterPdf
  include Prawn::View

  THIRD_COUNTRY = '103'.freeze
  TARIFF_PREFERENCE = '142'.freeze
  CUSTOM_UNION_DUTY = '106'.freeze
  PREFERENTIAL_MEASURE_TYPE_IDS = [ TARIFF_PREFERENCE, CUSTOM_UNION_DUTY ].freeze
  MEASUREMENT_UNITS = ["% vol", "% vol/hl", "ct/l", "100 p/st", "c/k", "10 000 kg/polar", "kg DHS", "100 kg", "100 kg/net eda", "100 kg common wheat", "100 kg/br", "100 kg live weight", "100 kg/net mas", "100 kg std qual", "100 kg raw sugar", "100 kg/net/%sacchar.", "EUR", "gi F/S", "g", "GT", "hl", "100 m", "kg C₅H₁₄ClNO", "tonne KCl", "kg", "kg/tot/alc", "kg/net eda", "GKG", "kg/lactic matter", "kg/raw sugar", "kg/dry lactic matter", "1000 l", "kg methylamines", "KM", "kg N", "kg H₂O₂", "kg KOH", "kg K₂O", "kg P₂O₅", "kg 90% sdt", "kg NaOH", "kg U", "l alc. 100%", "l", "L total alc.", "1000 p/st", "1000 pa", "m²", "m³", "1000 m³", "m", "1000 kWh", "p/st", "b/f", "ce/el", "pa", "TJ", "1000 kg", "1000 kg/net eda", "1000 kg/biodiesel", "1000 kg/fuel content", "1000 kg/bioethanol", "1000 kg/net mas", "1000 kg std qual", "1000 kg/net/%saccha.", "Watt"].freeze
  P_AND_R_MEASURE_TYPES_IMPORT = %w[277 705 724 745 410 420 465 474 475 707 710 712 714 722 728 730 746 747 748 750 755].freeze
  P_AND_R_MEASURE_TYPES_EXPORT = %w[278 706 740 749 467 473 476 478 479 708 709 715 716 717 718 725 735 751].freeze
  P_AND_R_MEASURE_TYPES_EXIM   = %w[760 719].freeze
  P_AND_R_MEASURE_TYPES = (P_AND_R_MEASURE_TYPES_IMPORT + P_AND_R_MEASURE_TYPES_EXIM + P_AND_R_MEASURE_TYPES_EXPORT).freeze
  ANTIDUMPING_MEASURE_TYPES = ().freeze
  SUPPORTED_CURRENCIES = {
    'BGN' => 'лв',
    'CZK' => 'Kč',
    'DKK' => 'kr.',
    'EUR' => '€', 
    'GBP' => '£',
    'HRK' => 'kn',
    'HUF' => 'Ft',
    'PLN' => 'zł',
    'RON' => 'lei',
    'SEK' => 'kr'
  }.freeze
  CURRENCY_REGEX = /([0-9]+\.?[0-9]*)\s€/.freeze

  CAP_LICENCE_KEY = 'CAP_LICENCE'
  CAP_REFERENCE_TEXT = 'CAP licencing may apply. Specific licence requirements for this commodity can be obtained from the Rural Payment Agency website (www.rpa.gov.uk) under RPA Schemes.'

  def initialize(opts = {})
    @opts = opts
    @chapter_id = opts[:chapter_id]

    @margin = [50, 50, 20, 50]
    @footer_height = 30
    @printable_height = 595.28 - (@margin[0] + @margin[2])
    @printable_width = 841.89 - (@margin[1] + @margin[3])
    @base_table_font_size = 8
    @indent_amount = 18
    @document = Prawn::Document.new(
      page_size: 'A4',
      margin: @margin,
      page_layout: :landscape
    )
    @cw = table_column_widths

    @currency = set_currency
    @currency_exchange_rate = fetch_exchange_rate
    
    @footnotes = {}
    @references_lookup = {}
    @quotas = {}
    @prs = {}
    @anti_dumpings = {}
    @pages_headings = {}

    set_fonts

    unless @chapter_id.to_s == 'test'
      @chapter = Uktt::Chapter.new(@opts.merge(chapter_id: @chapter_id, version: 'v2')).retrieve
      @section = Uktt::Section.new(@opts.merge(section_id: @chapter.data.relationships.section.data.id, version: 'v2')).retrieve
      @current_heading = @section[:data][:attributes][:position]
    end

    bounding_box([0, @printable_height],
                 width: @printable_width,
                 height: @printable_height - @footer_height) do
      if @chapter_id.to_s == 'test'
        test
        return
      else
        build
      end
    end

    repeat(:all, dynamic: true) do
      # trying to build a hash using page number as the key,
      # but `#curent_heading` returns the last value, not the current value (i.e., when the footer is rendered)
      if @pages_headings[page_number]
        @pages_headings[page_number] << @current_heading
      else
        @pages_headings[page_number] = ['01', @current_heading]
      end

      page_footer
    end
  end

  def set_currency
    cur = (SUPPORTED_CURRENCIES.keys & [@opts[:currency]]).first
    if cur = (SUPPORTED_CURRENCIES.keys & [@opts[:currency]]).first
      return cur.upcase
    else
      raise StandardError.new "`#{@opts[:currency]}` is not a supported currency. SUPPORTED_CURRENCIES = [#{SUPPORTED_CURRENCIES.keys.join(', ')}]"
    end
  end

  def set_fonts
    font_families.update('OpenSans' => {
                           normal: 'vendor/assets/Open_Sans/OpenSans-Regular.ttf',
                           italic: 'vendor/assets/Open_Sans/OpenSans-RegularItalic.ttf',
                           medium: 'vendor/assets/Open_Sans/OpenSans-SemiBold.ttf',
                           medium_italic: 'vendor/assets/Open_Sans/OpenSans-SemiBoldItalic.ttf',
                           bold: 'vendor/assets/Open_Sans/OpenSans-Bold.ttf',
                           bold_italic: 'vendor/assets/Open_Sans/OpenSans-BoldItalic.ttf'
                         })
    font_families.update('Monospace' => {
                           normal: 'vendor/assets/Overpass_Mono/OverpassMono-Regular.ttf',
                           bold: 'vendor/assets/Overpass_Mono/OverpassMono-Bold.ttf'
                         })
    font 'OpenSans'
    font_size @base_table_font_size
  end

  def fetch_exchange_rate(currency = @currency)
    return 1.0 unless currency

    return 1.0 if currency === Uktt::PARENT_CURRENCY

    response = ENV.fetch("MX_RATE_EUR_#{currency}") do |_missing_name|
      if currency === 'GBP'
        Uktt::MonetaryExchangeRate.new(version: 'v2').latest(currency)
      else
        raise StandardError.new "Non-GBP currency exchange rates are not available via API and must be manually set with an environment variable, e.g., 'MX_RATE_EUR_#{currency}'"
      end
    end.to_f

    return response if response > 0.0

    raise StandardError.new "Currency error. response=#{response.inspect}"
  end

  def test
    text "Today is #{Date.today}"
  end

  def build
    if @chapter.data.attributes.goods_nomenclature_item_id[0..1] == @section.data.attributes.chapter_from
      section_info
      pad(16) { stroke_horizontal_rule }
      start_new_page
    end

    chapter_info

    move_down(12)

    commodities_table

    pad_top(24) do
      font_size(13) do
        pad_bottom(4) { text('<b>Footnotes</b>', inline_format: true) }
      end
      pad_bottom(4) { stroke_horizontal_rule }
      footnotes
    end

    tariff_quotas

    prohibitions_and_restrictions

    anti_dumpings
  end

  def page_footer
    bounding_box([0, @footer_height],
                 width: @printable_width,
                 height: @footer_height) do
      table(footer_data, width: @printable_width) do |t|
        t.column(0).align = :left
        t.column(1).align = :center
        t.column(2).align = :right
        t.cells.borders = []
        t.cells.padding = 0
      end
    end
  end

  def footer_data
    # expecting something like this:
    # `@pages_headings = {1=>["01", "02", "03", "04"], 2=>["04", "05", "06"]}`
    footer_data_array = [[
      format_text("<font size=9>#{Date.today.strftime('%-d %B %Y')}</font>"),
      format_text("<b><font size='15'>#{@chapter.data.attributes.goods_nomenclature_item_id[0..1]}</font>#{Prawn::Text::NBSP * 2}#{page_number}</b>"),
      format_text("<b><font size=9>Customs Tariff</b> Vol 2 Sect #{@section.data.attributes.numeral}#{Prawn::Text::NBSP * 3}<b>#{@chapter.data.attributes.goods_nomenclature_item_id[0..1]} #{@pages_headings[page_number].first.to_s.rjust(2, "0")}-#{@chapter.data.attributes.goods_nomenclature_item_id[0..1]} #{@pages_headings[page_number].last.to_s.rjust(2, "0")}</font></b>")
    ]]
    footer_data_array
  end

  def format_text(text_in, leading = 0)
    {
      content: text_in,
      kerning: true,
      inline_format: true,
      leading: leading
    }
  end

  def indents(note)
    @this_indent ||= 0
    @next_indent ||= 0
    @top_pad     ||= 0

    case note
    when /^\d\.\s/
      @this_indent = 0
      @next_indent = 12
      @top_pad = @base_table_font_size / 2
    when /\([a-z]\)\s/
      @this_indent = 12
      @next_indent = 24
      @top_pad = @base_table_font_size / 2
    when /\-\s/
      @this_indent = 36
      @next_indent = 36
      @top_pad = @base_table_font_size / 2
    else
      @this_indent = @next_indent
      @top_pad = 0
    end
    @this_indent
  end

  def hanging_indent(array, opts = {}, header = nil, leading = 0)
    t = !header.nil? ? [[{ content: header, kerning: true, inline_format: true, colspan: 2, padding_bottom: 0 }, nil]] : []
    make_table(
      t << [
        format_text(array[0], leading),
        format_text(array[1], leading)
      ],
      opts
    ) do |t|
      t.cells.borders = []
      t.column(0).padding_right = 0
      t.row(0).padding_top = 0
    end
  end

  def text_indent(note, opts)
    if /<table.*/.match?(note)
      indent(0) do
        pad(@base_table_font_size) do
          render_html_table(note)
        end
      end
    else
      indent(indents(note)) do
        pad_top(@top_pad) do
          text("<b>#{note.strip}</b>", opts)
        end
      end
    end
  end

  def section_info(section = @section)
    section_note = section.data.attributes.section_note || ''

    if section_note.length > 3200
      opts = {
        width: @printable_width / 3,
        column_widths: [@indent_amount],
        cell_style: {
          padding_bottom: 0
        },
        inline_format: true,
      }
      column_box([0, cursor], columns: 3, width: bounds.width, height: (@printable_height - @footer_height - (@printable_height - cursor)), spacer: (@base_table_font_size * 3)) do
        text("<b><font size='13'>SECTION #{section.data.attributes.numeral}</font>\n<font size='17'>#{section.data.attributes.title}</font></b>", opts)

        move_down(@base_table_font_size * 1.5)

        text('<b>Notes</b>', opts.merge(size: 10))
        section_note.split(/\* /).each do |note|
          text_indent(note.gsub(%r{\\.\s}, '. '), opts.merge(size: 10))
        end
      end
    else
      opts = {
        width: @printable_width / 3,
        column_widths: [@indent_amount],
        cell_style: {
          padding_bottom: 0
        }
      }
      column_1 = format_text("<b><font size='13'>SECTION #{section.data.attributes.numeral}</font>\n<font size='17'>#{section.data.attributes.title}</font></b>")
      _column_x, column_2, column_3 = get_notes_columns(section.data.attributes.section_note, opts, 'Notes', 10)
      table(
        [
          [
            column_1,
            column_2,
            column_3
          ]
        ],
        column_widths: [@printable_width / 3, @printable_width / 3, @printable_width / 3]
      ) do |t|
        t.cells.borders = []
        t.column(0).padding_right = 12
        t.row(0).padding_top = 0
      end
    end
  end

  def chapter_info(chapter = @chapter)
    chapter_note = chapter.data.attributes.chapter_note || ''
    notes, additional_notes, *everything_else = chapter_note.split(/#+\s*[Additional|Subheading]+ Note[s]*\s*#+/i)
                                                            .map do |s|
                                                              s.delete('\\')
                                                              .gsub("\r\n\r\n", "\r\n")
                                                              # .strip
                                                            end

    notes ||= ''

    if (additional_notes && chapter_note.length > 2300) || chapter_note.length > 3200
      opts = {
        kerning: true,
        inline_format: true,
        size: @base_table_font_size
      }

      column_box([0, cursor], columns: 3, width: bounds.width, height: (@printable_height - @footer_height - (@printable_height - cursor) + 20), spacer: (@base_table_font_size * 3)) do
        text("<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}\n#{@chapter.data.attributes.formatted_description}</font></b>", opts)
        move_down(@base_table_font_size * 1.5)

        text('<b>Chapter notes</b>', opts.merge(size: 9))
        notes.split(/\* /).each do |note|
          text_indent(note, opts.merge(size: 9))
        end

        move_down(@base_table_font_size)

        if additional_notes
          text('<b>Subheading notes</b>', opts)
          move_down(@base_table_font_size / 2)
          additional_notes && additional_notes.split(/\* /).each do |note|
            text_indent(note, opts)
          end
          move_down(@base_table_font_size)
        end

        everything_else.each do |nn|
          text('<b>Additional notes</b>', opts)
          move_down(@base_table_font_size / 2)
          nn.to_s.split(/\* /).each do |note|
            text_indent(note, opts)
          end
        end
      end
    else
      opts = {
        width: @printable_width / 3,
        column_widths: [(@indent_amount + 2)],
        cell_style: {
          padding_bottom: 0
        }
      }
      column_x, column_2, column_3 = get_chapter_notes_columns(chapter.data.attributes.chapter_note, opts, 'Note', @chapter_notes_font_size)
      column_1 = if column_x.empty? || (column_x[0] && column_x[0][0][:content].blank?)
        format_text("<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}\n#{chapter.data.attributes.formatted_description}</font></b>")
      else
        column_x
      end
      table(
        [
          [
            column_1,
            column_2,
            column_3
          ]
        ],
        column_widths: [@printable_width / 3, @printable_width / 3, @printable_width / 3]
      ) do |t|
        t.cells.borders = []
        t.column(0).padding_right = 12
        t.row(0).padding_top = 0
      end
    end
  end

  def html_table_data(html)
    noko = Nokogiri::HTML(html)
    head = noko.at('th') ? noko.at('th').content : nil
    data = noko.css('tr').map do |tr|
      tr.css('td').map(&:content)
    end
    max_col_count = data.map(&:length).max
    data_normalized = data.reject do |row|
      row.length != max_col_count
    end
    return data_normalized.unshift([{content: head, colspan: max_col_count}]) if head

    data_normalized
  end

  def strip_tags(text)
    return if text.nil?

    noko = Nokogiri::HTML(text)
    noko.css('span', 'abbr').each { |node| node.replace(node.children) }
    noko.content
  end

  def render_html_table(html)
    html_string = "<table>#{html.gsub("\r\n", '')}</table>"
    table(html_table_data(html_string), cell_style: {
      padding: 2, 
      size: 5, 
      border_widths: [0.1, 0.1]
    } ) do |t|
      t.width = @printable_width / 3
    end
  end

  def update_footnotes(v2_commodity)
    measures = commodity_measures(v2_commodity)

    measure_footnote_ids = measures.map{|m| m.relationships.footnotes.data}.flatten.uniq.map(&:id)
    commodity_footnote_ids = v2_commodity.data.relationships.footnotes.data.flatten.uniq.map(&:id)
    footnotes = (commodity_footnote_ids + measure_footnote_ids).map do |f|
      v2_commodity.included.select{|obj| obj.id == f}
    end.flatten

    footnotes.each do |fn|
      f = fn.attributes
      next if f.code =~ /0[3,4]./
      if @footnotes[f.code]
        @footnotes[f.code][:refs] << @uktt.response.data.id
      else
        @footnotes[f.code] = {
          text: "#{f.code}-#{render_footnote(f.description)}",
          refs: [@uktt.response.data.id]
        }
        unless @references_lookup[footnote_reference_key(f.code)]
          @references_lookup[footnote_reference_key(f.code)] = {
            index: @references_lookup.length + 1,
            text: replace_html(@footnotes[f.code][:text].delete('|'))
          }
        end
      end
    end
  end

  def render_footnote(note)
    Nokogiri::HTML(note).css('p').map(&:content).join("\n")
  end

  def update_quotas(v2_commodity, heading)
    quotas = commodity_measures(v2_commodity).select{|m| measure_is_quota(m)}
    quotas.each do |measure_quota|
      order_number = measure_quota.relationships.order_number.data.id
      if @quotas[order_number]
        @quotas[order_number][:measures] << measure_quota
        @quotas[order_number][:commodities] << v2_commodity.data.attributes.goods_nomenclature_item_id
      else
        duty = v2_commodity.included.select{|obj| measure_quota.relationships.duty_expression.data.id == obj.id}.first.attributes.base
        definition_relation = v2_commodity.included.select{|obj| measure_quota.relationships.order_number.data.id == obj.id}.first.relationships.definition
        return if definition_relation.data.nil?
        definition = v2_commodity.included.select{|obj| definition_relation.data.id == obj.id}.first
        footnotes_ids  = measure_quota.relationships.footnotes.data.map(&:id).select{|f| f[0..1] == 'CD'}
        footnotes = v2_commodity.included.select{|obj| footnotes_ids.include?(obj.id)}

        @quotas[order_number] = {
          commodities: [v2_commodity.data.attributes.goods_nomenclature_item_id],
          descriptions: [[heading.description, v2_commodity.data.attributes.description]],
          measures: [measure_quota],
          duties: [duty],
          definitions: [definition],
          footnotes: footnotes
        }
      end
    end
  end

  def update_prs(v2_commodity)
    measures = pr_measures(v2_commodity)
    measures.each do |measure|
      document_codes = []
      requirements = []
      id = measure.relationships.measure_type.data.id

      if @prs[id]
        @prs[id][:commodities] << v2_commodity.data.attributes.goods_nomenclature_item_id
      else
        desc = v2_commodity.included.select{|obj| obj.type = "measure_type" && obj.id == id}.first.attributes.description
        conditions_ids = measure.relationships.measure_conditions.data.map(&:id)
        conditions = v2_commodity.included.select{|obj| obj.type = "measure_condition" && conditions_ids.include?(obj.id) }
        conditions.each do |condition|
          unless condition.nil?
            doc_code = condition.attributes.document_code
            document_codes << condition.attributes.document_code 
            requirements << "#{condition.attributes.condition_code}: #{strip_tags(condition.attributes.requirement)}#{" (#{doc_code})" unless doc_code.to_s.empty?}" unless condition.attributes.requirement.nil?
          end
        end
        @prs[id] = {
          measures: measure,
          commodities: [v2_commodity.data.attributes.goods_nomenclature_item_id],
          description: "#{desc} (#{id})",
          conditions: document_codes.reject(&:empty?),
          requirements: requirements.reject(&:nil?),
        }
      end
    end
  end

  def update_anti_dumpings(v2_commodity)
    anti_dumping_measures(v2_commodity).each do |measure|
      description = ''
      delimiter = ''

      duty_expression_id = measure.relationships.duty_expression&.data&.id
      if duty_expression_id
        duty_expression = find_duty_expression(duty_expression_id)
        unless duty_expression&.attributes&.base == ''
          measure_type = find_measure_type(measure.relationships.measure_type&.data&.id)
          description += clean_rates(duty_expression&.attributes&.base) + '<br>' + measure_type&.attributes&.description
          delimiter = '<br>'
        end
      end

      additional_code_id = measure.relationships.additional_code&.data&.id
      if additional_code_id
        additional_code = find_additional_code(additional_code_id)
        description += delimiter + additional_code.attributes.formatted_description
      end

      unless description == ''
        commodity_item_id = v2_commodity.data.attributes.goods_nomenclature_item_id
        geographical_area_id = measure.relationships.geographical_area.data.id
        @anti_dumpings[commodity_item_id] ||= {}
        @anti_dumpings[commodity_item_id][geographical_area_id] ||= {}
        @anti_dumpings[commodity_item_id][geographical_area_id][additional_code&.attributes&.code || ''] ||= description
      end
    end
  end

  def find_measure_type(measure_type_id)
    find_included_object(measure_type_id, 'measure_type')
  end

  def find_duty_expression(duty_expression_id)
    find_included_object(duty_expression_id, 'duty_expression')
  end

  def find_additional_code(additional_code_id)
    find_included_object(additional_code_id, 'additional_code')
  end

  def find_included_object(object_id, object_type)
    return nil unless object_id || object_type
    @uktt.response.included.find do |obj|
      obj.id == object_id && obj.type == object_type
    end
  end

  def commodities_table
    table commodity_table_data, header: true, column_widths: @cw do |t|
      t.cells.border_width = 0.25
      t.cells.borders = %i[left right]
      t.cells.padding_top = 2
      t.cells.padding_bottom = 2
      t.row(0).align = :center
      t.row(0).padding = 2
      t.column(1).align = :center
      t.column(2).align = :center
      t.column(5).align = :center
      t.row(0).borders = %i[top right bottom left]
      t.row(-1).borders = %i[right bottom left]
    end
  end

  def commodity_table_data(chapter = @chapter)
    result = [] << header_row
    heading_ids = chapter.data.relationships.headings.data.map(&:id)
    heading_objs = chapter.included.select{|obj| heading_ids.include? obj.id}
    heading_gniids = heading_objs.map{|h| h.attributes.goods_nomenclature_item_id}.uniq.sort

    heading_gniids.each do |heading_gniid|
      @uktt = Uktt::Heading.new(@opts.merge(heading_id: heading_gniid[0..3], version: 'v2'))
      v2_heading = @uktt.retrieve
      heading = v2_heading.data.attributes
      if heading.declarable
        update_footnotes(v2_heading)
        update_quotas(v2_heading, heading)
        update_prs(v2_heading)
        update_anti_dumpings(v2_heading)
      end

      result << heading_row_head(v2_heading)
      result << heading_row_title(v2_heading)

      # You'd think this would work, but `page_number` is not updated
      # because we're not inside the `repeat` block
      #
      # if @pages_headings[page_number]
      #   @pages_headings[page_number] << @current_heading
      # else
      #   @pages_headings[page_number] = [@current_heading]
      # end
      # logger.info @pages_headings.inspect

      # Same with below, but when trying to get the value of `@current_heading`
      # in the `repeat` block, it always returns the last value, not the current
      @current_heading = heading.goods_nomenclature_item_id[2..3]

      if v2_heading.data.relationships.commodities
        commodity_ids = v2_heading.data.relationships.commodities.data.map(&:id)
        commodity_objs = v2_heading.included.select{|obj| commodity_ids.include? obj.id}

        commodity_objs.each do |c|
          if c.attributes.leaf
            @uktt = Uktt::Commodity.new(@opts.merge(commodity_id: c.attributes.goods_nomenclature_item_id, version: 'v2'))
            v2_commodity = @uktt.retrieve

            if v2_commodity.data   
              result << commodity_row(v2_commodity)
              v2_commodity.data.attributes.description = c.attributes.description
              
              update_footnotes(v2_commodity) if v2_commodity.data.attributes.declarable

              update_quotas(v2_commodity, heading)

              update_prs(v2_commodity)

              update_anti_dumpings(v2_commodity)
            else
              result << commodity_row_subhead(c)
            end
          else
            result << commodity_row_subhead(c)
          end
        end
      end
    end
    result
  end

  def header_row
    %w[1 2A 2B 3 4 5 6 7]
  end

  def heading_row_head(v2_heading)
    heading = v2_heading.data.attributes
    head = {
      content: "<b>#{heading[:goods_nomenclature_item_id][0..1]} #{heading[:goods_nomenclature_item_id][2..3]}</b>",
      kerning: true,
      size: 12,
      borders: [],
      padding_bottom: 0,
      inline_format: true
    }
    [head, '', '', '', '', '', '', '']
  end

  def heading_row_title(v2_heading)
    heading = v2_heading.data.attributes
    title = {
      content: "<b>#{heading[:description].gsub('|', Prawn::Text::NBSP).upcase}<b>",
      kerning: true,
      size: @base_table_font_size,
      width: @cw[0],
      borders: [],
      padding_top: 0,
      inline_format: true
    }
    if heading.declarable
      heading_data = [
        commodity_code_cell(heading),               # Column 2A: Commodity code, 8 digits, center-align
        additional_commodity_code_cell(heading),    # Column 2B: Additional commodity code, 2 digits, center-align
        specific_provisions(v2_heading),            # Column 3:  Specific provisions, left-align
        units_of_quantity_list,                     # Column 4:  Unit of quantity, numbered list, left-align
        third_country_duty_expression,              # Column 5:  Full tariff rate, percentage, center align
        preferential_tariffs,                       # Column 6:  Preferential tariffs, left align
        formatted_vat_rate_cell                     # Column 7:  VAT Rate: e.g., 'S', 'Z', etc., left align
      ]
    else
      heading_data = ['', '', '', '', '', '', '']
    end
    [[[title]]] + heading_data
  end
  
  def commodity_row(v2_commodity)
    commodity = v2_commodity.data.attributes
    [
      formatted_heading_cell(commodity),            # Column 1:  Heading numbers and descriptions
      commodity_code_cell(commodity),               # Column 2A: Commodity code, 8 digits, center-align
      additional_commodity_code_cell(commodity),    # Column 2B: Additional commodity code, 2 digits, center-align
      specific_provisions(v2_commodity),            # Column 3:  Specific provisions, left-align
      units_of_quantity_list,                       # Column 4:  Unit of quantity, numbered list, left-align
      third_country_duty_expression,                # Column 5:  Full tariff rate, percentage, center align
      preferential_tariffs,                         # Column 6:  Preferential tariffs, left align
      formatted_vat_rate_cell                       # Column 7:  VAT Rate: e.g., 'S', 'Z', etc., left align
    ]
  end

  def commodity_row_subhead(c)
    commodity = c.attributes
    [
      formatted_heading_cell(commodity),
      commodity_code_cell(commodity),
      additional_commodity_code_cell(commodity),
      '',
      '',
      '',
      '',
      ''
    ]
  end

  def formatted_heading_cell(commodity)
    indents = (('-' + Prawn::Text::NBSP) * (commodity.number_indents - 1)) # [(commodity.number_indents - 1), 1].max)
    opts = {
      width: @cw[0],
      column_widths: { 0 => ((commodity.number_indents || 1) * 5.1) }
    }

    footnotes_array = []
    @footnotes.each_pair do |k, v|
      if @uktt.response.data && v[:refs].include?(@uktt.response.data.id) && k[0..1] != 'CD'
        footnotes_array << @references_lookup[footnote_reference_key(k)][:index]
      end
    end

    if footnotes_array.empty?
      footnote_references = ""
      leading = 0
    else
      footnote_references = " [#{footnotes_array.join(',')}]"
      leading = 4
    end

    # TODO: implement Commodity#from_harmonized_system? and Commodity#in_combined_nomenclature?
    # i.e.: (see below)
    # if commodity.from_harmonized_system? || commodity[:number_indents] <= 1
    #   content = format_text("<b>#{commodity.description}#{footnote_references}</b>")
    # elsif commodity.in_combined_nomenclature?
    #   content = hanging_indent(["<i>#{indents}<i>", "<i>#{commodity.description}#{footnote_references}</i>"], opts)
    # else
    #   content = hanging_indent([indents, "#{commodity.description}#{footnote_references}"], opts)
    # end
    description = render_special_characters(commodity.description)
    if commodity.number_indents.to_i <= 1 #|| !commodity.declarable
      format_text("<b>#{description}</b><font size='11'><sup><#{footnote_references}</sup></font>", leading)
    elsif commodity.declarable
      hanging_indent(["<i>#{indents}<i>", "<i><u>#{description}</u></i><font size='11'><sup>#{footnote_references}</sup></font>"], opts, nil, leading)
    elsif commodity.number_indents.to_i == 2
      hanging_indent([indents, "<b>#{description}</b><font size='11'><sup>#{footnote_references}</sup></font>"], opts, nil, leading)
    else
      hanging_indent([indents, "#{description}<font size='11'><sup>#{footnote_references}</sup></font>"], opts, nil, leading)
    end
  end

  def render_special_characters(string)
    string.gsub( /@([2-9])/, '<sub>\1 </sub>' )
          .gsub( /\|/, Prawn::Text::NBSP )
  end

  def commodity_code_cell(commodity)
    return '' unless commodity.declarable

    format_text "<font name='Monospace'>#{commodity.goods_nomenclature_item_id[0..5]}#{Prawn::Text::NBSP * 1}#{commodity.goods_nomenclature_item_id[6..7]}</font>"
  end

  def additional_commodity_code_cell(commodity)
    return '' unless commodity.declarable

    format_text "<font name='Monospace'>#{(commodity.goods_nomenclature_item_id[8..9]).to_s}</font>"
  end

  # copied from backend/app/models/measure_type.rb:41
  def measure_type_excise?(measure_type)
    measure_type&.attributes&.measure_type_series_id == 'Q'
  end

  def measure_type_anti_dumping?(measure_type)
    measure_type&.attributes&.measure_type_series_id == 'D'
  end

  def anti_dumping_measure_type_ids
    @uktt.response.included.select do |obj|
      obj.type == 'measure_type' && measure_type_anti_dumping?(obj)
    end.map(&:id)
  end

  def measure_type_tax_code(measure_type)
    measure_type.attributes.description.scan(/\d{3}/).first
  end

  def measure_type_suspension?(measure_type)
    measure_type&.attributes&.description =~ /suspension/
  end

  def measure_conditions_has_cap_license?(measure_conditions)
    measure_conditions.any? do |measure_condition|
      measure_condition&.attributes&.document_code == 'L001'
    end
  end

  def specific_provisions(v2_commodity)
    return '' unless v2_commodity.data.attributes.declarable

    measures = commodity_measures(v2_commodity)

    measure_types = measures.map do |measure|
      v2_commodity.included.find {|obj| obj.id == measure.relationships.measure_type.data.id && obj.type == 'measure_type'}
    end
    excise_codes = measure_types.select(&method(:measure_type_excise?)).map(&method(:measure_type_tax_code)).uniq.sort

    str = excise_codes.length > 0 ? "EXCISE (#{excise_codes.join(', ')})" : ''
    delimiter = str.length > 0 ? "\n" : ''

    str += measure_types.select(&method(:measure_type_suspension?)).length > 0 ? delimiter + 'S' : ''
    delimiter = str.length > 0 ? "\n" : ''

    str += (measures.select(&method(:measure_is_quota)).length > 0 ? delimiter + 'TQ' : '')
    delimiter = str.length > 0 ? "\n" : ''

    measure_conditions = measures.map do |measure|
      v2_commodity.included.find { |obj| measure.relationships.measure_conditions.data.map(&:id).include?(obj.id) && obj.type == 'measure_condition' }
    end.compact.uniq

    if measure_conditions_has_cap_license?(measure_conditions)
      unless @references_lookup[CAP_LICENCE_KEY]
        @references_lookup[CAP_LICENCE_KEY] = {
          index: @references_lookup.length + 1,
          text: CAP_REFERENCE_TEXT
        }
      end
      str += delimiter + "CAP Lic <font size='11'><sup> [#{@references_lookup[CAP_LICENCE_KEY][:index]}]</sup></font>"
    end
    format_text(str, 0)
  end

  def units_of_quantity_list
    str = ''
    duties = @uktt.find('duty_expression').map{ |d| d.attributes.base }
    return str if duties.empty?

    uoq = ['Kg']
    duties.each do |duty|
      uoq << duty if MEASUREMENT_UNITS.include?(duty)
    end

    uoq.each_with_index do |q, i|
      str << "#{(i + 1).to_s + '. ' if uoq.length > 1}#{q}\n"
    end

    str
  end

  def third_country_duty_expression
    measure = @uktt.find('measure').select{|m| m.relationships.measure_type.data.id == THIRD_COUNTRY }.first
    return '' if measure.nil?

    clean_rates(@uktt.find(measure.relationships.duty_expression.data.id).attributes.base)
  end

  def preferential_tariffs
    preferential_tariffs = {
      duties: {},
      footnotes: {},
      excluded: {},
    }
    s = []
    @uktt.find('measure').select{|m| PREFERENTIAL_MEASURE_TYPE_IDS.include?(m.relationships.measure_type.data.id) }.each do |t|
      g_id = t.relationships.geographical_area.data.id
      geo = @uktt.response.included.select{|obj| obj.id == g_id}.map{|t| t.id =~ /[A-Z]{2}/ ? t.id : t.attributes.description}.join(', ')

      d_id = t.relationships.duty_expression.data.id
      duty = @uktt.response.included.select{|obj| obj.id == d_id}.map{|t| t.attributes.base}

      f_ids = t.relationships.footnotes.data.map(&:id)
      footnotes = @uktt.response.included.select{|obj| f_ids.include? obj.id}.flatten

      x_ids = t.relationships.excluded_countries.data.map(&:id)
      excluded = @uktt.response.included.select{|obj| x_ids.include? obj.id}

      footnotes_string = footnotes.map(&:id).map{|fid| "<sup><font size='9'>[#{@references_lookup.dig(footnote_reference_key(fid), :index)}]</font></sup>"}.join(' ')
      excluded_string = excluded.map(&:id).map{|xid| " (Excluding #{xid})"}.join(' ')
      duty_string = clean_rates(duty.join, column: 6)
      s << "#{geo}#{excluded_string}-#{duty_string}#{footnotes_string}"
    end
    { content: s.sort.join(', '), inline_format: true }
  end

  def formatted_vat_rate_cell
    @uktt.find('measure_type')
         .map(&:id)
         .select{|id| id[0..1] == 'VT'}
         .map{|m| m.chars[2].upcase}
         .join(' ')
  end

  def footnotes
    return if @footnotes.size == 0

    cell_style = {
      padding: 0,
      borders: []
    }
    table_opts = {
      column_widths: [25],
      width: @printable_width,
      cell_style: cell_style
    }
    notes_array = @references_lookup.map do |_, reference|
      [ "( #{reference[:index]} )", reference[:text] ]
    end

    table notes_array, table_opts do |t|
      t.column(1).padding_left = 5
    end
  end

  def replace_html(raw)
    raw.gsub(/<P>/, "\n")
       .gsub(%r{</P>}, '')
       .gsub('&#38;', '&')
    # .gsub("\n\n", "\n")
  end

  def tariff_quotas(chapter = @chapter)
    cell_style = {
      padding: 0,
      borders: [],
      inline_format: true
    }
    table_opts = {
      column_widths: quota_table_column_widths,
      width: @printable_width,
      cell_style: cell_style
    }
    quotas_array = quota_header_row
    
    @quotas.each do |measure_id, quota|
      commodity_ids = quota[:commodities].uniq

      while commodity_ids.length > 0
        quotas_array << [
          quota_commodities(commodity_ids.shift(quotas_array.length == 2 ? 42 : 56)),
          quota_description(quota[:descriptions]),
          quota_geo_description(quota[:measures]),
          measure_id,
          quota_rate(quota[:duties]),
          quota_period(quota[:measures]),
          quota_units(quota[:definitions]),
          quota_docs(quota[:footnotes])
        ]
      end
    end

    unless quotas_array.length <= 2

      start_new_page

      font_size(19) do
        text "Chapter #{chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}#{Prawn::Text::NBSP * 4}<b>Additional Information</b>",
             inline_format: true
      end

      font_size(13) do
        pad_bottom(13) do
          text '<b>Tariff Quotas/Ceilings</b>',
               inline_format: true
        end
      end

      table quotas_array, table_opts do |t|
        t.cells.border_width = 0.25
        t.cells.borders = %i[top bottom]
        t.cells.padding_top = 2
        t.cells.padding_bottom = 4
        t.cells.padding_right = 9
        t.row(0).border_width = 1
        t.row(0).borders = [:top]
        t.row(1).borders = [:bottom]
        t.row(0).padding_top = 0
        t.row(0).padding_bottom = 0
        t.row(1).padding_top = 0
        t.row(1).padding_bottom = 2
      end
    end
  end

  def quota_header_row
    [
      [
        format_text('<b>Commodity Code</b>'),
        format_text('<b>Description</b>'),
        format_text('<b>Country of origin</b>'),
        format_text('<b>Tariff Quota Order No.</b>'),
        format_text('<b>Quota rate</b>'),
        format_text('<b>Quota period</b>'),
        format_text('<b>Quota units</b>'),
        format_text("<b>Documentary evidence\nrequired</b>")
      ],
      (1..8).to_a
    ]
  end

  def quota_commodities(commodities)
    commodities.map do |c|
      [
        c[0..3],
        c[4..5],
        c[6..7],
        c[8..-1]
      ].reject(&:empty?).join(Prawn::Text::NBSP)
    end.join("\n")
  end

  def quota_description(descriptions)
    # descriptions.flatten.join(' - ')
    descriptions.flatten[1]
  end

  def quota_geo_description(measures)
    measures.map do |measure|
      if @uktt.response.included
        geos = @uktt.response.included.select{|obj| obj.id == measure.relationships.geographical_area.data.id}
        geos.first.attributes.description unless geos.first.nil?
      end
    end.uniq.join(', ')
  end

  def quota_rate(duties)
    clean_rates(duties.uniq.join(', '))
  end

  def quota_period(measures)
    formatted_date = '%d/%m/%Y'
    measures.map do |m|
      start = m.attributes.effective_start_date ? DateTime.parse(m.attributes.effective_start_date).strftime(formatted_date) : ''
      ending = m.attributes.effective_end_date ? DateTime.parse(m.attributes.effective_end_date).strftime(formatted_date) : ''
      "#{start} - #{ending}"
    end.uniq.join(', ')
  end

  def quota_units(definitions)
    definitions.map do |d|
      d.attributes.measurement_unit
    end.uniq.join(', ')
  end

  def quota_docs(footnotes)
    return '' if footnotes.empty?
    footnotes.map do |f|
      f.attributes.description
    end.uniq.join(', ')
  end

  def get_chapter_notes_columns(content, opts, header_text = 'Note', _font_size = 9)
    get_notes_columns(content, opts, header_text, 9, 2)
  end

  def notes_str_to_note_array(notes_str)
    notes = []
    note_tmp = split_note(notes_str)
    while note_tmp.length >= 2
      notes << note_tmp[0..1]
      note_tmp = note_tmp[2..-1]
    end
    notes << note_tmp
  end

  def get_notes_columns(content, opts, header_text = 'Note', font_size = @base_table_font_size, fill_columns = 2)
    empty_cell = [{ content: '', borders: [] }]
    return [[empty_cell, empty_cell, empty_cell]] if content.nil?

    column_1 = []
    column_2 = []
    column_3 = []
    notes = []

    notes_str = content.delete('\\')
    notes = notes_str_to_note_array(notes_str)

    title = "<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{@chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}\n#{@chapter[:formatted_description]}</font></b>\n\n"
    offset = 0
    notes.each_with_index do |note, i|
      m = note.join.match(/##\s*(additional|subheading) note[s]*\s*##/i)
      if m
        note[0], note[1] = '', ''
        header = "#{fill_columns == 3 ? title : nil}<b><font size='#{font_size}'>#{"#{m[1]} Note"}</font></b>"
        offset += 1
      else
        header = i.zero? ? "#{fill_columns == 3 ? title : nil}<b><font size='#{font_size}'>#{header_text}</font></b>" : nil
      end
      new_note = [
        {
          content: hanging_indent([
                                    "<b><font size='#{font_size}'>#{note[0]}</font></b>",
                                    "<b><font size='#{font_size}'>#{note[1]}</font></b>"
                                  ], opts, header),
          borders: []
        }
      ]
      if fill_columns == 2
        if i - offset < (notes.length / 2)
          column_2 << new_note unless new_note == ['', '']
        else
          column_3 << new_note
        end
      elsif fill_columns == 3
        if i < (notes.length / 3)
          column_1 << new_note
        elsif i < ((notes.length / 3) * 2)
          column_2 << new_note
        else
          column_3 << new_note
        end
      end
    end

    column_2 << empty_cell if column_2.empty?
    column_3 << empty_cell if column_3.empty?
    [column_1, column_2, column_3]
  end

  def split_note(str)
    arr = str.split(/\* |^([0-9]\.{0,}\s|\([a-z]{1,}\))/)
             .map { |n| n.split(/^([0-9]\.{0,}\s{0,}|\([a-z]{1,}\))/) }
             .each { |n| n.unshift(Prawn::Text::NBSP) if n.length == 1 }
             .flatten
             .reject(&:empty?)
             .map(&:strip)
    return arr.unshift((Prawn::Text::NBSP * 2)) if arr.length == 1

    normalize_notes_array(arr)
  end

  def token?(str)
    str =~ /^[0-9]\.{0,}\s{0,}|\([a-z]{1,}\)|\s{1,}/
  end

  def normalize_notes_array(arr)
    arr.each_with_index do |str, i|
      if str == Prawn::Text::NBSP && i.odd?
        arr.delete_at(i)
        normalize_notes_array(arr)
      end
    end
  end

  def table_column_widths
    column_ratios = [21, 5, 1.75, 5, 4, 5.25, 19, 2]
    multiplier = @printable_width / column_ratios.sum
    column_ratios.map { |n| n * multiplier }
  end

  def quota_table_column_widths
    column_ratios = [12, 43, 9, 9, 11, 11, 8, 22]
    multiplier = 741.89 / column_ratios.sum
    column_ratios.map { |n| n * multiplier }
  end

  def pr_table_column_widths
    column_ratios = [2, 1, 4, 4, 1]
    multiplier = 741.89 / column_ratios.sum
    column_ratios.map { |n| n * multiplier }
  end

  def anti_dumping_table_column_widths
    column_ratios = [1, 1, 1, 4]
    multiplier = 741.89 / column_ratios.sum
    column_ratios.map { |n| n * multiplier }
  end

  def clean_rates(raw, column: nil)
    rate = raw

    if column != 6
      rate = rate.gsub(/^0.00 %/, 'Free')
    end

    rate = rate.gsub(' EUR ', ' € ')
               .gsub(' / ', '/')
               .gsub(/(\.[0-9]{1})0 /, '\1 ')
               .gsub(/([0-9]{1})\.0 /, '\1 ')

    CURRENCY_REGEX.match(rate) do |m|
      rate = rate.gsub(m[0], "#{convert_currency(m[1])} #{currency_symbol} ")
    end

    rate
  end

  def commodity_measures(commodity)
    ids = commodity.data.relationships.import_measures.data.map(&:id) + commodity.data.relationships.export_measures.data.map(&:id)

    commodity.included.select{|obj| ids.include? obj.id}
  end

  def measure_is_quota(measure)
    !measure.relationships.order_number.data.nil?
  end

  def measure_footnotes(measure)
    measure.relationships.footnotes.data.map
  end

  def measure_duty_expression(measure)
    measure.relationships.duty_expression.data
  end

  def pr_measures(v2_commodity)
    # c = Uktt::Commodity.new(commodity_id: '3403910000')
    # v2 = c.retrieve
    v2_commodity.included.select{|obj| obj.type == 'measure' && measure_is_pr(obj)}
  end

  def anti_dumping_measures(v2_commodity)
    anti_dumping_ids = anti_dumping_measure_type_ids
    v2_commodity.included.select{ |obj| obj.type == 'measure' && anti_dumping_ids.include?(obj.relationships.measure_type.data.id) }
  end

  def measure_is_pr(measure)
    P_AND_R_MEASURE_TYPES.include?(measure.relationships.measure_type.data.id)
  end

  def prohibitions_and_restrictions
    cell_style = {
      padding: 0,
      borders: [],
      inline_format: true
    }
    table_opts = {
      column_widths: pr_table_column_widths,
      width: @printable_width,
      cell_style: cell_style
    }
    prs_array = pr_header_row

    @prs.each do |id, pr|

      commodity_ids = pr[:commodities].uniq

      while commodity_ids.length > 0
        prs_array << [
          quota_commodities(commodity_ids.shift(prs_array.length == 2 ? 46 : 56)),
          pr[:measures].attributes.import ? "Import" : "Export", # Import/Export
          pr[:description], # Description, was Measure Type Code
          pr[:requirements].join("<br/><br/>"), # Requirements, was Measure Group Code
          pr[:conditions].join("<br/>"), # Document Code/s
          # '', # Ex-heading Indicator
        ]
      end
    end

    unless prs_array.length <= 2 || false

      start_new_page

      font_size(19) do
        text "Chapter #{@chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}#{Prawn::Text::NBSP * 4}<b>Additional Information</b>",
             inline_format: true
      end

      font_size(13) do
        pad_bottom(13) do
          text '<b>Prohibitions and Restrictions</b>',
               inline_format: true
        end
      end

      table prs_array, table_opts do |t|
        t.cells.border_width = 0.25
        t.cells.borders = %i[top bottom]
        t.cells.padding_top = 4
        t.cells.padding_bottom = 6
        t.cells.padding_right = 9
        t.row(0).border_width = 1
        t.row(0).borders = [:top]
        t.row(1).borders = [:bottom]
        t.row(0).padding_top = 0
        t.row(0).padding_bottom = 0
        t.row(1).padding_top = 0
        t.row(1).padding_bottom = 2
      end
    end
  end

  def pr_header_row
    [
      [
        format_text('<b>Commodity Code</b>'),
        format_text('<b>Import/ Export</b>'),
        format_text('<b>Description</b>'), # format_text('<b>Measure Type Code</b>'),
        format_text('<b>Requirements</b>'), # format_text('<b>Measure Group Code</b>'),
        format_text('<b>Document Code/s</b>'),
        # format_text('<b>Ex-heading Indicator</b>')
      ],
      (1..5).to_a
    ]
  end

  def anti_dumpings
    return if @anti_dumpings.empty?

    # group commodities by goods nomenclature item id and additional codes
    grouped = @anti_dumpings.group_by do |_, value|
      value.keys.sort.map do |k|
        "#{k.to_s}_#{value[k].keys.sort.join('_')}"
      end.join('_')
    end.map do |_, value|
      { value.map(&:first) => value.first.last }
    end.inject({}, &:merge)

    output = anti_dumping_header_row
    # represent each line from grouped data as 3+ rows - 1st goods nomenclatures, 2nd geo area id + 1st info row, 3rd and next - rest of the rows with info
    output += grouped.map do |goods_nomenclature_item_ids, data|
      [
        # 1st row
        [ make_cell(quota_commodities(goods_nomenclature_item_ids), borders: []), make_cell("", borders: []), make_cell("", borders: []), make_cell("", borders: []) ],
      ].concat(
        data.map do |geographical_area_id, additional_codes|
          [
            # 2nd row
            [ make_cell("", borders: []), make_cell(geographical_area_id, borders: []), make_cell(additional_codes.first.first, borders: []), make_cell(additional_codes.first.last, borders: []) ]
          ].concat(
            # 3rd and next, show additional_code_id only on first line only
            additional_codes.drop(1).map do |additional_code_id, description|
              description.split(/<br\/?>/).map do |description_line|
                borders = description.index(description_line) === 0 ? [:top] : []
                additional_code_text = description.index(description_line) === 0 ? additional_code_id : ""
                [ make_cell("", borders: []), make_cell("", borders: []), make_cell(additional_code_text, borders: borders), make_cell(description_line, borders: borders) ]
              end
            end.flatten(1)
          ).push([ make_cell("", borders: []),
              make_cell("", { borders: %i[bottom] }),
              make_cell("", { borders: %i[bottom] }),
              make_cell("", { borders: %i[bottom] }) ]
          )
        end.flatten(1)
      ).tap(&:pop).push([ make_cell("", { borders: %i[bottom] }),
          make_cell("", { borders: %i[bottom] }),
          make_cell("", { borders: %i[bottom] }),
          make_cell("", { borders: %i[bottom] }) ]
      )
    end.flatten(1)

    start_new_page

    font_size(19) do
      text "Chapter #{@chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}#{Prawn::Text::NBSP * 4}<b>Additional Information</b>",
        inline_format: true
    end

    font_size(13) do
      pad_bottom(13) do
        text '<b>Anti-dumping duties</b>',
          inline_format: true
      end
    end

    cell_style = {
      padding: 0,
      inline_format: true
    }
    table_opts = {
      column_widths: anti_dumping_table_column_widths,
      width: @printable_width,
      cell_style: cell_style
    }

    table output, table_opts do |t|
      t.cells.border_width = 0.25
      t.cells.padding_right = 9
      t.row(0).border_width = 1
      t.row(0).borders = [:top]
      t.row(1).borders = [:bottom]
      t.row(0).padding_top = 0
      t.row(0).padding_bottom = 0
      t.row(1).padding_top = 0
      t.row(1).padding_bottom = 2
      output[2..-1].each_with_index do |line, i|
        t.row(i + 2).padding_top = "#{line[0]}#{line[1]}#{line[2]}" == '' ? 0 : 6
      end
    end
  end

  def anti_dumping_header_row
    [
      [
        format_text('<b>Commodity Code</b>'),
        format_text('<b>Country of Origin</b>'),
        format_text('<b>Additional Code</b>'),
        format_text('<b>Description/Rate of Duty/Additional Information</b>'),
      ],
      (1..4).to_a
    ]
  end

  def convert_currency(amount, precision = 1)
    (amount.to_f * @currency_exchange_rate).round(precision)
  end

  def currency_symbol
    return '€' unless @currency

    SUPPORTED_CURRENCIES[@currency]
  end

  UNIT_ABBREVIATIONS = {
    'Number of items'.to_sym => 'Number',
    'Hectokilogram'.to_sym => 'Kg'
  }.freeze

  RECIPIENT_SHORTENER = {
    # 'EU-Canada agreement: re-imported goods'.to_sym => 'EU-CA',
    # 'Economic Partnership Agreements'.to_sym => 'EPA',
    # 'Eastern and Southern Africa States'.to_sym => 'ESAS',
    # 'GSP (R 12/978) - Annex IV'.to_sym => 'GSP-AX4',
    # 'OCTs (Overseas Countries and Territories)'.to_sym => 'OCT',
    # 'GSP+ (incentive arrangement for sustainable development and good governance)'.to_sym => 'GSP+',
    # 'SADC EPA'.to_sym => 'SADC',
    # 'GSP (R 12/978) - General arrangements'.to_sym => 'GSP-GA',
    # 'GSP (R 01/2501) - General arrangements'.to_sym => 'GSP',
    # 'Central America'.to_sym => 'CEN-AM',
  }.freeze
  private

  def footnote_reference_key(footnote_code)
    "FOOTNOTE-#{footnote_code}"
  end
end
