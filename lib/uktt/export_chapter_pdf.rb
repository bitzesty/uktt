require 'prawn'
require 'prawn/table'

class ExportChapterPdf
  include Prawn::View

  THIRD_COUNTRY = '103'.freeze

  def initialize(chapter_id, json, host, version, debug)
    @host = host
    @version = version
    @chapter_id = chapter_id
    @return_json = false      # force to FALSE, `ExportChapterPdf` uses Openstruct/ruby hash
    @debug = debug
    
    @margin = [50,50,20,50]
    @footer_height = 30
    @printable_height = 595.28 - ( @margin[0] + @margin[2] )
    @printable_width = 841.89 - ( @margin[1] + @margin[3] )
    @base_table_font_size = 8
    @indent_amount = 18
    @document = Prawn::Document.new({
      page_size: 'A4',
      margin: @margin,
      page_layout: :landscape,
    })

    @cw = table_column_widths
    @footnotes, @footnotes_lookup = {}, {}
    @quotas = {}
    @pages_headings = {}

    set_fonts

    unless chapter_id.to_s == 'test'
      @chapter = Uktt::Chapter.new(chapter_id, @json, @host, @version, @debug).retrieve
      @section = Uktt::Section.new(@chapter[:section][:id], @json, @host, @version, @debug).retrieve
      @current_heading = @section[:formatted_position]
    end

    bounding_box([0,@printable_height],
      width: @printable_width,
      height: @printable_height - @footer_height
    ) do
      if chapter_id.to_s == 'test'
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
        @pages_headings[page_number] = ["01", @current_heading]
      end

      page_footer
    end
  end

  def set_fonts
    font_families.update("CabinCondensed" => {
      :normal =>        "vendor/assets/Cabin_Condensed/CabinCondensed-Regular.ttf",
      :bold =>          "vendor/assets/Cabin_Condensed/CabinCondensed-Bold.ttf",
    })
    font_families.update("Cabin" => {
      :normal =>        "vendor/assets/Cabin/Cabin-Regular.ttf",
      :italic =>        "vendor/assets/Cabin/Cabin-Italic.ttf",
      :medium =>        "vendor/assets/Cabin/Cabin-Medium.ttf",
      :medium_italic => "vendor/assets/Cabin/Cabin-MediumItalic.ttf",
      :bold =>          "vendor/assets/Cabin/Cabin-Bold.ttf",
      :bold_italic =>   "vendor/assets/Cabin/Cabin-BoldItalic.ttf",
    })
    font "Cabin"
    font_size @base_table_font_size
  end

  def test
    text "Today is #{Date.today.to_s}"
  end

  def build

    if @chapter[:goods_nomenclature_item_id][0..1] == @section[:chapter_from]
      section_info
      pad(16) { stroke_horizontal_rule }
    end

    chapter_info

    move_down(12)

    commodities_table

    pad_top(24) {
      pad_bottom(4) { stroke_horizontal_rule }
      footnotes
    }

    tariff_quotas
  end

  def page_footer
    bounding_box([0, @footer_height],
      width: @printable_width,
      height: @footer_height
    ) do
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
      format_text("<font size=9 name='CabinCondensed'>#{Date.today.strftime('%-d %B %Y')}</font>"),
      format_text("<b><font size='15' name='CabinCondensed'>#{@chapter[:short_code]}</font>#{Prawn::Text::NBSP * 2}#{page_number}</b>"),
      format_text("<b><font size=9 name='CabinCondensed'>Customs Tariff</b> Vol 2 Sect #{@section[:numeral]}#{Prawn::Text::NBSP * 3}<b>#{@chapter[:short_code]} #{@pages_headings[page_number].first}-#{@chapter[:short_code]} #{@pages_headings[page_number].last}</font></b>")
    ]]
    return footer_data_array
  end

  def format_text(text_in)
    {
      content: text_in,
      kerning: true,
      inline_format: true,
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
    return @this_indent
  end

  def hanging_indent(array, opts={}, header=nil)
    t = !header.nil? ? [[{content: header, kerning: true, inline_format: true, colspan: 2, padding_bottom: 0}, nil]] : []
    make_table(
      t << [
        format_text(array[0]),
        format_text(array[1]),
      ],
      opts,
    ) do |t|
      t.cells.borders = []
      t.column(0).padding_right = 0
      t.row(0).padding_top = 0
    end
  end

  def text_indent(note, opts)
    indent(indents(note)) do
      pad_top(@top_pad) do
        text("<b>#{note.strip}</b>", opts)
      end
    end
  end

  def section_info(section=@section)
    opts = {
      width: @printable_width/3,
      column_widths: [@indent_amount],
      cell_style: {
        padding_bottom: 0,
      }
    }
    column_1 = format_text("<b><font size='13'>SECTION #{section[:numeral]}</font>\n<font size='17'>#{section[:title]}</font></b>")
    column_x, column_2, column_3 = get_notes_columns(section[:section_note], opts, "Notes", 10)
    table(
      [
        [
          column_1,
          column_2,
          column_3,
        ]
      ],
      column_widths: [ @printable_width/3, @printable_width/3, @printable_width/3 ]
    ) do |t|
      t.cells.borders = []
      t.column(0).padding_right = 12
      t.row(0).padding_top = 0
    end
  end

  def chapter_info(chapter=@chapter)
    notes, additional_notes, *everything_else = chapter[:chapter_note]
                                                       .to_s
                                                       .split(/#+\s{0,}[Additional|Subheading]+ Note[s]{0,}\s{0,}#+/i)
                                                       .map{|s|
                                                        s.gsub(/\\/, '')
                                                         .gsub("\r\n\r\n", "\r\n")
                                                         .strip
                                                       }

    if additional_notes
      opts = {
        kerning: true,
        inline_format: true,
        size: @base_table_font_size,
      }

      column_box([0, cursor], :columns => 3, :width => bounds.width, height: (@printable_height - @footer_height - (@printable_height - cursor) + 20), spacer: (@base_table_font_size*3)) do
        text("<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{@chapter[:goods_nomenclature_item_id][0..1].gsub(/^0/, '')}\n#{@chapter[:formatted_description]}</font></b>", opts)
        move_down(@base_table_font_size * 1.5)

        text("<b>Note</b>", opts.merge({size: 9}))
        notes.split(/\* /).each do |note|
          text_indent(note, opts.merge({size: 9}))
        end

        move_down(@base_table_font_size)

        text("<b>Additional Notes</b>", opts)
        move_down(@base_table_font_size/2)
        additional_notes.split(/\* /).each do |note|
          text_indent(note, opts)
        end

        move_down(@base_table_font_size)

        everything_else.each do |nn|
          text("<b>Notes</b>", opts)
          move_down(@base_table_font_size/2)
          nn.to_s.split(/\* /).each do |note|
            text_indent(note, opts)
          end
        end
      end
    else
      opts = {
        width: @printable_width/3,
        column_widths: [@indent_amount],
        cell_style: {
          padding_bottom: 0,
        },
      }
      column_x, column_2, column_3 = get_chapter_notes_columns(chapter[:chapter_note], opts, "Note", @chapter_notes_font_size)
      if column_x.empty? || (column_x[0] && column_x[0][0][:content].blank?)
        column_1 = format_text("<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{@chapter[:goods_nomenclature_item_id][0..1].gsub(/^0/, '')}\n#{@chapter[:formatted_description]}</font></b>")
      else
        column_1 = column_x
      end
      table(
        [
          [
            column_1,
            column_2,
            column_3,
          ]
        ],
        column_widths: [ @printable_width/3, @printable_width/3, @printable_width/3 ]
      ) do |t|
        t.cells.borders = []
        t.column(0).padding_right = 12
        t.row(0).padding_top = 0
      end
    end
  end

  def update_footnotes(commodity)
    commodity[:import_measures]
      .map do |m|
        m[:footnotes].map do |f|

          if @footnotes[f[:code]]
            @footnotes[f[:code]][:refs] << commodity[:goods_nomenclature_sid]
          else
            @footnotes[f[:code]] = {
              text: f[:description],
              refs: [ commodity[:goods_nomenclature_sid] ]
            }
            unless @footnotes_lookup[f[:code]]
              @footnotes_lookup[f[:code]] = @footnotes_lookup.length + 1
            end
          end

        end
      end
    # commodity.import_measures_dataset
    #          .map(&:footnotes)
    #          .map{|f|
    #            f.each{ |ff|
    #             if @footnotes[ff.footnote_id]
    #               @footnotes[ff.footnote_id][:refs] << commodity.goods_nomenclature_sid
    #             else
    #               @footnotes[ff.footnote_id] = {
    #                 text: ff.description,
    #                 refs: [ commodity.goods_nomenclature_sid ]
    #               }
    #               unless @footnotes_lookup[ff.footnote_id]
    #                 @footnotes_lookup[ff.footnote_id] = @footnotes_lookup.length + 1
    #               end
    #             end
    #            }
    #          }
  end

  def update_quotas(commodity, heading)
    return if commodity[:import_measures].nil?
    commodity[:import_measures]
      .select { |m| !m[:order_number].nil? }
      .each do |measure| 
        q = measure[:order_number]

        if @quotas[q]
          @quotas[q][:commodities] << commodity[:goods_nomenclature_item_id]
          @quotas[q][:measures] << measure unless measure[:order_number] == @quotas[q][:measures][0][:order_number]
        else
          @quotas[q] = {
            commodities: [ commodity[:goods_nomenclature_item_id] ],
            measures: [ measure ],
            descriptions: [ [heading[:description], commodity[:description]] ]
          }
        end

      end
    # quota_measures = commodity.import_measures_dataset
    #           .reject{|m| m.quota_order_number.nil?}
    #           .select(&:valid?)
    # quota_measures.each do |measure|
    #   q = measure.quota_order_number
    #   if @quotas[q]
    #     @quotas[q][:commodities] << commodity[:goods_nomenclature_item_id]
    #     @quotas[q][:measures] << measure unless measure.ordernumber == @quotas[q][:measures][0].ordernumber
    #   else
    #     @quotas[q] = {
    #       commodities: [ commodity[:goods_nomenclature_item_id] ],
    #       measures: [ measure ]
    #     }
    #   end
    # end
  end

  def commodities_table
    table commodity_table_data, column_widths: @cw do |t|
      t.cells.border_width = 0.25
      t.cells.borders = [:left, :right]
      t.cells.padding_top = 2
      t.cells.padding_bottom = 2
      t.row(0).align = :center
      t.row(0).padding = 2
      t.column(1).align = :center
      t.column(2).align = :center
      t.column(5).align = :center
      t.row(0).borders = [:top, :right, :bottom, :left]
      t.row(-1).borders = [:right, :bottom, :left]
    end
  end

  def commodity_table_data(chapter=@chapter)
    result = [] << header_row

    chapter[:headings] && chapter[:headings].each do |openstruct|
      h = openstruct.to_h
      heading = Uktt::Heading.new(h[:goods_nomenclature_item_id][0..3], @json, @host, @version, @debug).retrieve.to_h
      heading = h.merge(heading)

      result << heading_row(heading)

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
      @current_heading = heading[:goods_nomenclature_item_id][2..3]

      heading[:commodities] && heading[:commodities].each do |openstruct|
        c = openstruct.to_h
        commodity = Uktt::Commodity.new(c[:goods_nomenclature_item_id], @json, @host, @version, @debug).retrieve.to_h
        commodity = c.merge(commodity)

        update_footnotes(commodity) if commodity[:declarable]

        update_quotas(commodity, heading)

        result << commodity_row(commodity)
      end
    end

    result
  end

  def header_row
    %w(1 2A 2B 3 4 5 6 7)
  end

  def heading_row(heading)
    head = {
      content: "<b><font name='CabinCondensed'>#{heading[:goods_nomenclature_item_id][0..1]} #{heading[:goods_nomenclature_item_id][2..3]}</font></b>",
      kerning: true,
      size: 12,
      borders: [],
      padding_bottom: 0,
      inline_format: true,
    }
    title = {
      content: "<b><font name='CabinCondensed'>#{heading[:description].upcase}</font><b>",
      kerning: true,
      size: @base_table_font_size,
      width: @cw[0],
      borders: [],
      inline_format: true,
    }
    [
        [[head],[title]],
        '', '', '', '', '', '', ''
    ]
  end

  def commodity_row(commodity)
    [
        formatted_heading_cell(commodity),          # Column 1:  Heading numbers and descriptions
        commodity_code_cell(commodity),             # Column 2A: Commodity code, 8 digits, center-align
        additional_commodity_code_cell(commodity),  # Column 2B: Additional commodity code, 2 digits, center-align
        specific_provisions(commodity),             # Column 3:  Specific provisions, left-align
        units_of_quantity_list(commodity),          # Column 4:  Unit of quantity, numbered list, left-align
        third_country_duty_expression(commodity),   # Column 5:  Full tariff rate, percentage, center align
        preferential_tariffs(commodity),            # Column 6:  Preferential tariffs, left align
        formatted_vat_rate_cell(commodity)          # Column 7:  VAT Rate: e.g., 'S', 'Z', etc., left align
    ]
  end

  def formatted_heading_cell(commodity)
    indents = "#{('-' + Prawn::Text::NBSP) * (commodity[:number_indents] ? commodity[:number_indents] - 1 : 0)}"
    opts = {
      width: @cw[0],
      column_widths: { 0 => ((commodity[:number_indents] ? commodity[:number_indents] : 1) * 5.1) },
    }

    footnotes_array = []
    @footnotes.each_pair do |k,v|
      footnotes_array << @footnotes_lookup[k] if v[:refs].include?(commodity[:goods_nomenclature_sid])
    end

    footnote_references = !footnotes_array.empty? ? " (#{footnotes_array.join(',')})" : ''

    # TODO: implement Commodity#from_harmonized_system? and Commodity#in_combined_nomenclature?
    # i.e.: (see below)
    # if commodity.from_harmonized_system? || commodity[:number_indents] <= 1
    #   content = format_text("<b>#{commodity.description}#{footnote_references}</b>")
    # elsif commodity.in_combined_nomenclature?
    #   content = hanging_indent(["<i>#{indents}<i>", "<i>#{commodity.description}#{footnote_references}</i>"], opts)
    # else
    #   content = hanging_indent([indents, "#{commodity.description}#{footnote_references}"], opts)
    # end
    description = commodity[:description].gsub('|', '')
    if commodity[:number_indents].to_i <= 1 || !commodity[:declarable]
      content = format_text("<b>#{description}#{footnote_references}</b>")
    elsif commodity[:declarable]
      content = hanging_indent(["<i>#{indents}<i>", "<i>#{description}#{footnote_references}</i>"], opts)
    else
      content = hanging_indent([indents, "#{description}#{footnote_references}"], opts)
    end
    content
  end

  def commodity_code_cell(commodity)
    return '' unless commodity[:declarable]
    format_text "#{commodity[:goods_nomenclature_item_id][0..5]}#{Prawn::Text::NBSP * 3}#{commodity[:goods_nomenclature_item_id][6..7]}"
  end

  def additional_commodity_code_cell(commodity)
    return '' unless commodity[:declarable]
    format_text "#{commodity[:goods_nomenclature_item_id][8..9]}"
  end

  def specific_provisions(commodity)
    return '' unless commodity[:declarable]
    commodity[:import_measures]
             .reject{ |m| m[:order_number].nil? }
             .any? ? 'TQ' : ''
  end

  def units_of_quantity_list(commodity)
    return '' unless commodity[:import_measures]
    str = ''
    uoq = ['Kg']
    uoq << 'Number' if commodity[:import_measures].detect do |import_measure|
      import_measure[:duty_expression][:base] == 'p/st'
    end

    uoq.each_with_index do |q, i|
      str << "#{(i+1).to_s + '.' if uoq.length > 1}#{q}\n"
    end

    return str
  end

  def third_country_duty_expression(commodity)
    return '' unless commodity[:import_measures]
    commodity[:import_measures].filter do |import_measure|
      import_measure[:measure_type][:description] == 'Third country duty'
    end
    .map do |import_measure|
      clean_rates(import_measure[:duty_expression][:base])
    end
    .join(' ') || ''

    # return '' unless commodity[:declarable]
    # commodity.import_measures_dataset.filter(measures__measure_type_id: MeasureType::THIRD_COUNTRY).map do |measure|
    #   measure.duty_expression
    #          .gsub('0.00 %', 'Free')
    #          .gsub(' EUR ', ' € ')
    #          .gsub(/(.[0-9]{1})0 /, '\1 ')
    # end.join(' ') || ''
  end

  def preferential_tariffs(commodity)
    return '' unless commodity[:declarable]
    return 'zero' if commodity[:import_measures].filter{ |m| m[:measure_type][:id] == THIRD_COUNTRY}.map{ |m| m[:duty_expression] }.first == "0.00 %"

    preferential_tariffs_array = commodity[:import_measures].filter{ |m| !!(m[:measure_type][:description] =~ /Tariff preference/) }
    .map do |m| 
      [
        m[:duty_expression][:base],
        m[:geographical_area][:id],
        m[:geographical_area][:description],
      ]
    end
    .uniq
    # preferential_tariffs_array = commodity[:measures]
    #   .select do |m|
    #     m.measure_type.tariff_preference?
    #   end
    #   .map do |m|
    #     [
    #       m.duty_expression_with_national_measurement_units_for(m).gsub('0.00 %', 'Free'),
    #       m.geographical_area.geographical_area_id,
    #       m.geographical_area.description,
    #     ]
    #   end
    #   .uniq
    return '' if preferential_tariffs_array.empty?

    preferential_tariffs = {}
    preferential_tariffs_array.each do |tariff|
      recipient = tariff[1] =~ /[0-9]{1,}/ ? tariff[2] : tariff[1]
      if preferential_tariffs[tariff[0]]
        preferential_tariffs[tariff[0]] << recipient
      else
        preferential_tariffs[tariff[0]] = [recipient]
      end
    end

    s = []
    preferential_tariffs.each_pair do |k,v|
      shortened = v.map do |recipient|
        RECIPIENT_SHORTENER[recipient.to_sym] ? RECIPIENT_SHORTENER[recipient.to_sym] : recipient
      end
      s.push "#{shortened.join(', ')}-#{clean_rates(k)}"
    end
    return s.join('; ')
  end

  def formatted_vat_rate_cell(commodity)
    # content = commodity.import_measures_dataset
    #                    .reject{ |m| !m.vat? }
    #                    .map{ |m| m.measure_type_id.chars[2].upcase }
    #                    .uniq
    #                    .sort
    #                    .join(' ')
    # get VAT rates from import measures
    content = commodity[:import_measures] ? commodity[:import_measures]
      .reject{ |m| !m[:vat] }
      .map{ |m| m[:measure_type][:id].chars[2].upcase}
      .join(' ') : ''
    {
      content: content,
    }
  end

  def footnotes
    cell_style = {
      padding: 0,
      borders: [],
    }
    table_opts = {
      column_widths: [@indent_amount],
      width: @printable_width,
      cell_style: cell_style,
    }
    notes_array = []
    @footnotes.each_pair do |k,v|
      text = v[:text]
      index = @footnotes_lookup[k]
      notes_array << ["( #{index} )", replace_html(text.gsub('|', ''))]
    end

    table notes_array, table_opts do |t|
      t.column(1).padding_left = 5
    end
  end

  def replace_html(raw)
    raw.gsub(/<P>/, "\n")
      .gsub(/<\/P>/, '')
      .gsub('&#38;', '&')
      # .gsub("\n\n", "\n")
  end

  def tariff_quotas(chapter=@chapter)
    cell_style = {
      padding: 0,
      borders: [],
    }
    table_opts = {
      column_widths: quota_table_column_widths,
      width: @printable_width,
      cell_style: cell_style,
    }
    quotas_array = quota_header_row

    @quotas.each do |quota_order, data|
      measure = data[:measures] ? data[:measures][0] : nil
      quotas_array << [
        quota_commodities(data[:commodities]),  # Commodity </font>, list of codes, 1 per line, with comma
        quota_description(data[:descriptions]), # Description
        quota_geo_description(measure),         # Country of origin, e.g. GATT, NCC, others, Israel, etc.
        quota_order_no(quota_order),            # Tariff Quota Order No.
        quota_rate(measure),                    # Quota rate
        quota_period(quota_order),              # Quota period, date range
        quota_units(quota_order),               # Quota units, e.g., pieces, kg, number
        quota_docs(measure)                     # Documentary evidence required
      ]
    end

    unless quotas_array.length <= 2

      start_new_page

      font_size(19) {
        text "Chapter #{chapter[:goods_nomenclature_item_id][0..1].gsub(/^0/, '')}#{Prawn::Text::NBSP * 4}<b>Additional Information</b>",
          inline_format: true
      }

      font_size(13) {
        pad_bottom(13) {
          text "<b>Tariff Quotas/Ceilings</b>",
            inline_format: true
        }
      }

      table quotas_array, table_opts do |t|
        t.cells.border_width = 0.25
        t.cells.borders = [:top, :bottom]
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
        format_text("<b>Commodity Code</b>"),
        format_text("<b>Description</b>"),
        format_text("<b>Country of origin</b>"),
        format_text("<b>Tariff Quota Order No.</b>"),
        format_text("<b>Quota rate</b>"),
        format_text("<b>Quota period</b>"),
        format_text("<b>Quota units</b>"),
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
    descriptions.first.join(' - ')
  end

  def quota_geo_description(measure)
    measure[:geographical_area][:description]
  end

  def quota_order_no(quota_order)
    quota_order[:number]
  end

  def quota_rate(measure)
    return '' if measure.nil?
    clean_rates(measure[:duty_expression][:base].to_s)
  end

  def quota_period(quota_order)
    qo = quota_order[:definition]
    return '' if qo.nil?
    return "#{DateTime.parse(qo[:validity_start_date]).strftime('%-d.%-m')}" if qo[:validity_end_date].nil?
    "#{DateTime.parse(qo[:validity_start_date]).strftime('%-d.%-m')}-#{DateTime.parse(qo[:validity_end_date]).strftime('%-d.%-m')}"
  end

  def quota_units(quota_order)
    return '' if quota_order[:definition].nil?
    q = quota_order[:definition][:measurement_unit]
    return '' if q.nil?
    UNIT_ABBREVIATIONS.key?(q.to_sym) ? UNIT_ABBREVIATIONS[q.to_sym] : q
  end

  def quota_docs(measure)
    return '' if measure.nil?
    measure[:footnotes]
            .select{|f| f[:footnote_type_id] == 'CD'} # get "conditions" type of footnotes only
            .flatten
            .uniq
            .map{ |f| f[:description]}
            .join("\n")
  end

  # def quota_geo_description(quota_order)
  #   begin
  #     id = quota_order.quota_order_number_origin.geographical_area_id
  #     GeographicalArea.find(geographical_area_id: id.to_s).description
  #   rescue => exception
  #     puts exception.inspect
  #     return ''
  #   end
  # end

  # def quota_period(quota)
  #   return "foo" if quota[:validity_start_date].nil?
  #   return "#{quota[:validity_start_date].strftime('%-d.%-m')}" if quota[:validity_end_date].nil?
  #   "#{quota[:validity_start_date].strftime('%-d.%-m')}-#{quota[:validity_end_date].strftime('%-d.%-m')}"
  # end

  def get_chapter_notes_columns(content, opts, header_text="Note", font_size=9)
    return get_notes_columns(content, opts, header_text, 9, 2)
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

  def get_notes_columns(content, opts, header_text="Note", font_size=@base_table_font_size, fill_columns=2)
    empty_cell = [{ content: "", borders: [] }]
    return [[empty_cell, empty_cell, empty_cell]] if content.nil?
    column_1, column_2, column_3, notes = [], [], [], []

    notes_str = content.gsub(/\\/, '')
    notes = notes_str_to_note_array(notes_str)

    title = "<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{@chapter[:goods_nomenclature_item_id][0..1].gsub(/^0/, '')}\n#{@chapter[:formatted_description]}</font></b>\n\n"
    notes.each_with_index do |note, i|
      header = i == 0 ? "#{fill_columns == 3 ? title : nil}<b><font size='#{font_size}'>#{header_text}</font></b>" : nil
      new_note = [
        {
          content: hanging_indent([
            "<b><font size='#{font_size}'>#{note[0]}</font></b>",
            "<b><font size='#{font_size}'>#{note[1]}</font></b>"
          ], opts, header ),
          borders: [],
        }
      ]

      if fill_columns == 2
        if i < (notes.length / 2)
          column_2 << new_note
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
             .map{|n| n.split(/^([0-9]\.{0,}\s{0,}|\([a-z]{1,}\))/)}
             .each{|n| n.unshift(Prawn::Text::NBSP) if n.length == 1}
             .flatten
             .reject(&:empty?)
             .map(&:strip)
    if arr.length == 1
      return arr.unshift((Prawn::Text::NBSP * 2))
    else
      return normalize_notes_array(arr)
    end
  end

  def is_token?(str)
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
    column_ratios.map{ |n| n * multiplier }
  end

  def quota_table_column_widths
    column_ratios = [12, 43, 9, 9, 11, 11, 8, 22]
    multiplier = 741.89 / column_ratios.sum
    column_ratios.map{ |n| n * multiplier }
  end

  def clean_rates(raw)
    raw.gsub('0.00 %', 'Free')
      .gsub(' EUR ', ' € ')
      .gsub(/(\.[0-9]{1})0 /, '\1 ')
      .gsub(/([0-9]{1})\.0 /, '\1 ')
  end

  UNIT_ABBREVIATIONS = {
    'Number of items'.to_sym => "Number",
    'Hectokilogram'.to_sym => "Kg"
  }

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
  }

end
