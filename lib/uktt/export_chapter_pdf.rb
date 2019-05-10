require 'prawn'
require 'prawn/table'

# A class to produce a PDF for a single chapter
class ExportChapterPdf
  include Prawn::View

  THIRD_COUNTRY = '103'.freeze
  TARIFF_PREFERENCE = '142'.freeze

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
    @footnotes = {}
    @footnotes_lookup = {}
    @quotas = {}
    @pages_headings = {}

    set_fonts

    unless @chapter_id.to_s == 'test'
      @chapter = Uktt::Chapter.new(@opts.merge(chapter_id: @chapter_id, version: 'v2')).retrieve
      @section = Uktt::Section.new(@opts.merge(section_id: @chapter.data.relationships.section.data.id, version: 'v2')).retrieve
      @current_heading = @section[:formatted_position]
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

  def set_fonts
    font_families.update('CabinCondensed' => {
                           normal: 'vendor/assets/Cabin_Condensed/CabinCondensed-Regular.ttf',
                           bold: 'vendor/assets/Cabin_Condensed/CabinCondensed-Bold.ttf'
                         })
    font_families.update('Cabin' => {
                           normal: 'vendor/assets/Cabin/Cabin-Regular.ttf',
                           italic: 'vendor/assets/Cabin/Cabin-Italic.ttf',
                           medium: 'vendor/assets/Cabin/Cabin-Medium.ttf',
                           medium_italic: 'vendor/assets/Cabin/Cabin-MediumItalic.ttf',
                           bold: 'vendor/assets/Cabin/Cabin-Bold.ttf',
                           bold_italic: 'vendor/assets/Cabin/Cabin-BoldItalic.ttf'
                         })
    font 'Cabin'
    font_size @base_table_font_size
  end

  def test
    text "Today is #{Date.today}"
  end

  def build
    if @chapter.data.attributes.goods_nomenclature_item_id[0..1] == @section.data.attributes.chapter_from
      section_info
      pad(16) { stroke_horizontal_rule }
    end

    chapter_info

    move_down(12)

    commodities_table

    pad_top(24) do
      pad_bottom(4) { stroke_horizontal_rule }
      footnotes
    end

    tariff_quotas
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
      format_text("<font size=9 name='CabinCondensed'>#{Date.today.strftime('%-d %B %Y')}</font>"),
      format_text("<b><font size='15' name='CabinCondensed'>#{@chapter.data.attributes.goods_nomenclature_item_id[0..1]}</font>#{Prawn::Text::NBSP * 2}#{page_number}</b>"),
      format_text("<b><font size=9 name='CabinCondensed'>Customs Tariff</b> Vol 2 Sect #{@section.data.attributes.numeral}#{Prawn::Text::NBSP * 3}<b>#{@chapter.data.attributes.goods_nomenclature_item_id[0..1]} #{@pages_headings[page_number].first}-#{@chapter.data.attributes.goods_nomenclature_item_id[0..1]} #{@pages_headings[page_number].last}</font></b>")
    ]]
    footer_data_array
  end

  def format_text(text_in)
    {
      content: text_in,
      kerning: true,
      inline_format: true
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

  def hanging_indent(array, opts = {}, header = nil)
    t = !header.nil? ? [[{ content: header, kerning: true, inline_format: true, colspan: 2, padding_bottom: 0 }, nil]] : []
    make_table(
      t << [
        format_text(array[0]),
        format_text(array[1])
      ],
      opts
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

  def section_info(section = @section)
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

  def chapter_info(chapter = @chapter)
    chapter_note = chapter.data.attributes.chapter_note || ''
    notes, additional_notes, *everything_else = chapter_note
      .split(/#+\s*[Additional|Subheading]+ Note[s]*\s*#+/i)
      .map do |s|
        s.delete('\\')
        .gsub("\r\n\r\n", "\r\n")
        .strip
      end

    notes ||= ''

    if additional_notes || notes.length > 3200
      opts = {
        kerning: true,
        inline_format: true,
        size: @base_table_font_size
      }

      column_box([0, cursor], columns: 3, width: bounds.width, height: (@printable_height - @footer_height - (@printable_height - cursor) + 20), spacer: (@base_table_font_size * 3)) do
        text("<b><font size='#{@base_table_font_size * 1.5}'>Chapter #{chapter.data.attributes.goods_nomenclature_item_id[0..1].gsub(/^0/, '')}\n#{@chapter.data.attributes.formatted_description}</font></b>", opts)
        move_down(@base_table_font_size * 1.5)

        text('<b>Note</b>', opts.merge(size: 9))
        notes.split(/\* /).each do |note|
          text_indent(note, opts.merge(size: 9))
        end

        move_down(@base_table_font_size)

        text('<b>Additional Notes</b>', opts)
        move_down(@base_table_font_size / 2)
        additional_notes && additional_notes.split(/\* /).each do |note|
          text_indent(note, opts)
        end

        move_down(@base_table_font_size)

        everything_else.each do |nn|
          text('<b>Notes</b>', opts)
          move_down(@base_table_font_size / 2)
          nn.to_s.split(/\* /).each do |note|
            text_indent(note, opts)
          end
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

  def update_footnotes(v2_commodity)
    measures = commodity_measures(v2_commodity)

    footnote_ids = measures.map{|m| m.relationships.footnotes.data}.flatten.uniq.map(&:id)
    footnotes = footnote_ids.map do |f|
      v2_commodity.included.select{|obj| obj.id == f}
    end.flatten

    footnotes.each do |fn|
      f = fn.attributes
      next if f.code =~ /0[3,4]./
      if @footnotes[f.code]
        @footnotes[f.code][:refs] << @uktt.response.data.id
      else
        @footnotes[f.code] = {
          text: "#{f.code}-#{f.description}",
          refs: [@uktt.response.data.id]
        }
        unless @footnotes_lookup[f.code]
          @footnotes_lookup[f.code] = @footnotes_lookup.length + 1
        end
      end
    end
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

  def commodities_table
    table commodity_table_data, column_widths: @cw do |t|
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
      v2_heading = Uktt::Heading.new(@opts.merge(heading_id: heading_gniid[0..3], version: 'v2')).retrieve
      heading = v2_heading.data.attributes
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
      @current_heading = heading.goods_nomenclature_item_id[2..3]


      if v2_heading.data.relationships.commodities
        commodity_ids = v2_heading.data.relationships.commodities.data.map(&:id)
        commodity_objs = v2_heading.included.select{|obj| commodity_ids.include? obj.id}

        commodity_objs.each do |c|
          if c.attributes.leaf
            @uktt = Uktt::Commodity.new(@opts.merge(commodity_id: c.attributes.goods_nomenclature_item_id, version: 'v2'))
            v2_commodity = @uktt.retrieve

            if v2_commodity.data
              commodity = v2_commodity.data.attributes
              
              update_footnotes(v2_commodity) if commodity.declarable

              update_quotas(v2_commodity, heading)

              result << commodity_row(v2_commodity)
              v2_commodity.data.attributes.description = c.attributes.description
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

  def heading_row(heading)
    head = {
      content: "<b><font name='CabinCondensed'>#{heading[:goods_nomenclature_item_id][0..1]} #{heading[:goods_nomenclature_item_id][2..3]}</font></b>",
      kerning: true,
      size: 12,
      borders: [],
      padding_bottom: 0,
      inline_format: true
    }
    title = {
      content: "<b><font name='CabinCondensed'>#{heading[:description].upcase}</font><b>",
      kerning: true,
      size: @base_table_font_size,
      width: @cw[0],
      borders: [],
      inline_format: true
    }
    [
      [[head], [title]],
      '', '', '', '', '', '', ''
    ]
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
        footnotes_array << @footnotes_lookup[k]
      end
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
    description = commodity.description # .delete('|')
    if commodity.number_indents.to_i <= 1 #|| !commodity.declarable
      format_text("<b>#{description}</b>#{footnote_references}")
    elsif commodity.declarable
      hanging_indent(["<i>#{indents}<i>", "<i>#{description}</i>#{footnote_references}"], opts)
    else
      hanging_indent([indents, "#{description}#{footnote_references}"], opts)
    end
  end

  def commodity_code_cell(commodity)
    return '' unless commodity.declarable

    format_text "#{commodity.goods_nomenclature_item_id[0..5]}#{Prawn::Text::NBSP * 3}#{commodity.goods_nomenclature_item_id[6..7]}"
  end

  def additional_commodity_code_cell(commodity)
    return '' unless commodity.declarable

    format_text (commodity.goods_nomenclature_item_id[8..9]).to_s
  end

  def specific_provisions(v2_commodity)
    return '' unless v2_commodity.data.attributes.declarable

    commodity_measures(v2_commodity).select{|m| measure_is_quota(m)}.length > 0 ? 'TQ' : ''
  end

  def units_of_quantity_list
    duties = @uktt.find('duty_expression').map{|d| d.attributes.base }
    return '' if duties.empty?

    str = ''
    uoq = ['Kg']
    uoq << 'Number' if duties.include?('p/st')
    uoq << 'Litre' if duties.include?('l')

    uoq.each_with_index do |q, i|
      str << "#{(i + 1).to_s + '.' if uoq.length > 1}#{q}\n"
    end

    str
  end

  def third_country_duty_expression
    measure = @uktt.find('measure').select{|m| m.relationships.measure_type.data.id == THIRD_COUNTRY }.first
    return '' if measure.nil?

    @uktt.find(measure.relationships.duty_expression.data.id).attributes.base
  end

  def preferential_tariffs
    preferential_tariffs = {
      duties: {},
      footnotes: {},
      excluded: {},
    }
    s = []
    @uktt.find('measure').select{|m| m.relationships.measure_type.data.id == TARIFF_PREFERENCE }.each do |t|
      g_id = t.relationships.geographical_area.data.id
      geo = @uktt.response.included.select{|obj| obj.id == g_id}.map{|t| t.id =~ /[A-Z]{2}/ ? t.id : t.attributes.description}.join(', ')

      d_id = t.relationships.duty_expression.data.id
      duty = @uktt.response.included.select{|obj| obj.id == d_id}.map{|t| t.attributes.base}

      f_ids = t.relationships.footnotes.data.map(&:id)
      footnotes = @uktt.response.included.select{|obj| f_ids.include? obj.id}.flatten

      x_ids = t.relationships.excluded_countries.data.map(&:id)
      excluded = @uktt.response.included.select{|obj| x_ids.include? obj.id}

      footnotes_string = footnotes.map(&:id).map{|fid| " (#{@footnotes_lookup[fid]})"}.join(' ')
      excluded_string = excluded.map(&:id).map{|xid| " (Excluding #{xid})"}.join(' ')
      duty_string = duty.join.gsub('0.00 %', 'Free')
      s << "#{geo}#{excluded_string}-#{duty_string}#{footnotes_string}"
    end
    s.sort.join('; ')
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
      column_widths: [@indent_amount],
      width: @printable_width,
      cell_style: cell_style
    }
    notes_array = []
    @footnotes.each_pair do |k, v|
      text = v[:text]
      index = @footnotes_lookup[k]
      notes_array << ["( #{index} )", replace_html(text.delete('|'))]
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
      borders: []
    }
    table_opts = {
      column_widths: quota_table_column_widths,
      width: @printable_width,
      cell_style: cell_style
    }
    quotas_array = quota_header_row
    
    @quotas.each do |measure_id, quota|
      # measure = data[:measures] ? data[:measures][0] : nil
      # quotas_array << [
      #   quota_commodities(data[:commodities]),  # Commodity </font>, list of codes, 1 per line, with comma
      #   quota_description(data[:descriptions]), # Description
      #   quota_geo_description(measure),         # Country of origin, e.g. GATT, NCC, others, Israel, etc.
      #   quota_order_no(measure),                # Tariff Quota Order No.
      #   quota_rate(measure),                    # Quota rate
      #   quota_period(quota_order),              # Quota period, date range
      #   quota_units(quota_order),               # Quota units, e.g., pieces, kg, number
      #   quota_docs(measure)                     # Documentary evidence required
      # ]

      quotas_array << [
        quota_commodities(quota[:commodities]),
        quota_description(quota[:descriptions]),
        quota_geo_description(quota[:measures]),
        measure_id,
        quota_rate(quota[:duties]),
        quota_period(quota[:measures]),
        quota_units(quota[:definitions]),
        quota_docs(quota[:footnotes])
      ]
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
    # @uktt.response.included.select{|obj| obj.id == measure.relationships.geographical_area.data.id}.first.attributes.description
    measures.map do |measure|
      measure.relationships.geographical_area.data.id
    end.uniq.join(', ')
  end

  def quota_rate(duties)
    duties.uniq.join(', ')
  end

  def quota_period(measures)
    measures.map do |m|
      start = m.attributes.effective_start_date ? DateTime.parse(m.attributes.effective_start_date).strftime('%-d.%-m') : ''
      ending = m.attributes.effective_end_date ? DateTime.parse(m.attributes.effective_end_date).strftime('%-d.%-m') : ''
      "#{start}-#{ending}"
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
    notes.each_with_index do |note, i|
      header = i.zero? ? "#{fill_columns == 3 ? title : nil}<b><font size='#{font_size}'>#{header_text}</font></b>" : nil
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

  def clean_rates(raw)
    raw.gsub('0.00 %', 'Free')
       .gsub(' EUR ', ' € ')
       .gsub(/(\.[0-9]{1})0 /, '\1 ')
       .gsub(/([0-9]{1})\.0 /, '\1 ')
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
end
