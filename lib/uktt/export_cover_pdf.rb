require 'prawn'

# A class to produce a PDF for the Tariff cover and explantion of the columns in the Schedule
class ExportCoverPdf
  include Prawn::View

  def initialize(opts = {})
    @opts = opts

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

    set_fonts

    bounding_box([0, @printable_height],
                 width: @printable_width,
                 height: @printable_height - @footer_height) do
      build
    end

    repeat(:all, dynamic: true) do
      page_footer unless page_number == 1
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

  def format_text(text_in)
    {
      content: text_in,
      kerning: true,
      inline_format: true
    }
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
    footer_data_array = [[
      format_text("<font size=9>#{Date.today.strftime('%-d %B %Y')}</font>"),
      format_text("<b>#{'i' * (page_number - 1)}</b>"),
      format_text("<font size=9><b>Customs Tariff</b> Vol 2</font>")
    ]]
    footer_data_array
  end

  def build
    cover

    start_new_page

    layout
  end

  def cover
    opts = {
      kerning: true,
      inline_format: true,
      size: @base_table_font_size
    }
    image "vendor/assets/HMRC-logo.png", width: 180
    text_box "<font size='20'><b>Volume 2</b></font>\n<font size='17'>Schedule of duty and trade\nstatistical descriptions,\ncodes and rates</font>", at: [(@printable_width / 3), @printable_height - 100], inline_format: true
    text_box "<font size='32'>Integrated\nTariff of the\nUnited Kingdom</font>\n\n\n<font size='12'>Short title: <i>TARIFF</i>\n\n\nwww.gov.uk/trade-tariff\n\n\n<b>#{Date.today.strftime('%Y')} EDITION</b>\n\n\n\n\n\n\n\nLONDON: TSO\n#{Date.today.strftime('%-d %B %Y')}</font>", at: [(@printable_width / 3) * 2 + (@base_table_font_size * 3), @printable_height - 100], inline_format: true
    stroke_rectangle [0, @printable_height - 200], ((@printable_width / 3) * 2), 190
    text_box "<font size='11'><b><u>Notice to all Users</u></b></font>", at: [20, @printable_height - 210], inline_format: true, width: ((@printable_width / 3) * 2) - 40, align: :center
    text_box "<font size='11'><b>#{notice_content}</b></font>", at: [20, @printable_height - 228], inline_format: true, width: ((@printable_width / 3) * 2) - 40
  end

  def notice_content
    <<~NOTICE
    Users should be aware that in any case where information in the UK Tariff or Customs Handling of Import and Export Freight (CHIEF) system is at variance with that contianed in the appropirate Community legislation published in the Official Journal of the European Communities, the latter will represent the correct legal position.
    Whilst every effort is made to ensre the accuracy of the UK Tariff, the onus remains with the User to consult the Official Journal as necessary and to ensure that the correct duties are paid at importation. In instances where the Customs Authorities are at error, the User may still be liable for any additional duty that may be demanded as a result of that error being discovered.
    The Official Journal is accessible on the Commission's Europa website:
    https://eur-lex.europa.eu/oj/direct-access.html
    NOTICE
  end

  def layout
    opts = {
      kerning: true,
      inline_format: true,
      size: @base_table_font_size
    }
    column_box([0, cursor], columns: 3, width: bounds.width, height: (@printable_height - @footer_height - (@printable_height - cursor) + 20), spacer: (@base_table_font_size * 3)) do
      text(layout_content, opts)
    end
  end

  def layout_content
    <<~CONTENT
      <font size="13"><b>VOLUME 2 Part 1</b></font>
      <font size="17"><b>Guide to the Schedule</b></font>

      <font size="13"><b>Section 1: Introduction</b></font>

      <b>1.1 - The Integrated Tariff</b>

      Both the UK Tariff and the Combined Nomenclature of the EC are based on the based on the internationally agreed system of classification known as the Harmonized Commodity Description and Coding System of the Customs Co-operation Council. This nomenclature provides a systematic classification of all goods in international trade, designed to ensure, with the aid of the General Rules for the interpretation of the Nomenclature (see below) and Notes to the Sections, Chapters and Subheadings, that any product or article falls to be classified in one place and one place only.

      <b>1.2 The schedule of the Integrated Tariff ('the Schedule')</b>

      A guide to the general system of classification is provided by the Section and Chapter titles which are set out separtately immediately before the Schedule. The Schedule combines:

      1.2.1 - The Harmonized Commodity Description and Coding System of the Customs Co-operation Council (short title: the Harmonized System and referred to as the HS).

      1.2.2 - The Combined Nomenclature of the European Community.

      1.2.3 - other tariff related mneasures of the European Community, including preferences, quotas, suspensions, and measures connected with the common agricultural policy integrated into the schedule (short title: TARIC). A list of measures included in TARIC will be found in Section 5.

      1.2.4 - UK excise duty requirements, except hydrocarbon oil duty descriptions generally (see Section 2).


      <font size="13"><b>Section 2: Layout of the Schedule</b></font>

      <b>2.1 - Column 1 - Heading numbers and descriptions</b>

      2.1.1 - The Column contains:
      - heading numbers (4 digits) and descriptions which derive from the main headings of the Harmonized System. These are printed in <b>BOLD CAPITALS</b> and indicate the scope of headings;
      - subheadings which also derive from the Harmonized System. These are printed in <b>bold lowercase</b> type;
      - subheadings included for Combined Nomenclature printed in medium type;
      - other subheadings printed in <i>light italicised</i> type, describing particular goods subject to tariff measures (TARIC).

      2.1.2 - Specimens of the various forms and presentations of integrated headings and subheadings, are shown in the layout above and are described in the following sub-paragraph.

      2.1.3 - In the specimen layout above:

          '48.09 CARBON PAPER ... OR SHEETS' is an HS heading that is further subdivided into HS subheadings, some of which are further subdivided into Community subheadings.

          'Tarred, bituminized or asphalted paper and paerboard' is an HS subheading for which no further breakdown exists for Community purposes.

          'Carbon or similar copying papers' is a Combined Nomenclature sub-division.

      2.1.4 - Headings and subheadings followed by the term '(EURATOM)' are goods covered by the European Atomic Energy Commission Treaty. The presence of this term does not affect the scope of any heading or sub-heading.

      2.1.5 - Where the reference '(TEXT and 3 digits)' appears after a description in this column, it indicates the textile category that applies.

      <b>2.2 - Column 2 - Commodity Codes</b>

      2.2.1 - In addition to the heading numbers and descriptions which appear under column 1, provision is made under column 2 for the classification of goods to be indicated by a commodity code number unique to each heading or subheading. Subject to the exceptions set out below, in the case of goods moving within the Community (intra-EC goods) and all exports, only the code number which appears under column 2A should be used. Imports from non-EC countries should be classified in accordance with the code number which combines columns 2A and 2B.

      2.2.2 - <b>Column 2A - 8 digits.</b> The first four digits are those of the Harmonized System (HS) headings and the fifth and sixth represent HS subheadings. EC Combined Nomenclature requirements are met by the seventh and eighth digits. For intra-EC movement of goods not in free circulation, for whch a C88SAD entry is completd and for exports to non-EC countries only the 8-digit code should be used.

      2.2.3 - <b>Column 2B - 2 digits.</b> this colum provides for two additional digits to cover EC-related tariff and related measures which, in general, apply only to importations from non-EC countries and which have been included in the integrated tariff of the Community. Where no further breakdown of the Combined Nomenclature is required to accomodate tariff measures (most preferences, for example) the two digits are 00 and are shown on the same line as the 8-digit code. Subheadings established for TARIC purposes are shown in light italicised type and are notable for the fact that only the two digits of column 2 appear against the descriptions. They are included after the breakdown of headings at 8-digit level to avoid repetition and to spare the tariff user concerned only with intra-Community trade and exports from having to consider TARIC descriptions which apply in the main only to imports from outside the Community.

      <b>The declaration of a combined 10-digit code is mandatory for importations from outside the Community even where the 2 two characters are both zero.</b>

      2.2.4 <b>Additional code. (general). Imports from outside the Community that are subject to anti-dumping duties or subject to agricultural component (in most cases) will also require an additional code of 4 digits to be declared in conjunction with the 10-digit code. In such instacnes where the additional code is required it is to be declared in conjunction with the 8-digit code. A footnote reference appears in Column 3 of the Schedule against TARIC lines which require the additional code to be used.</b>

      2.2.5 - <b>Examples.</b> The following 2 examples, based on the specimen included at paragraph 2.1.2 above, illustrate how the level 2 code operates in practice:

      Example 1: The 8-digit code 481200 00 would be appropriate for goods falling within heading 4812 and coming from a Community source while the 10-digit code 481200 00 00 would be required for the same goods imported from a non-community source.

      Example 2: The goods described at lines 11-20 imported from an EC source would have to be coded only at the 8-digit level 481121 00 while similar goods from a non-Community source would require the full 10-digit code 481121 00 10.

      <b>It is important to remember that the last two digits should be selected only after the 8-digit code has been determined.</b>

      <b>2.3 - Column 3 - Specific Provisions</b>

      This column indcludes a variety of information for a wide range of purposes. The detail is frequently in abbreviated form. A key to symbols and abbreviations will be found at the end of this Part, and Section 5 contains a fuller explanation of the tariff measures integrated in the Schedule. Information that is too detailed to be included in the column will appear as a footnote, or at the end of the relevant Chapter.

      <b>2.4 - Column 4 - Unit of Quantity</b>

      The satandard quantity is the kilogram. For some subheadings however a second quantity declaration is required, normally when duties (customs or excise) are calculated on a specific basis. Occasionally a third quantity must be declared.

      <b>2.5  - Column 5 - Full rate of duty</b>

      The rate of duty shown is the rate applicable under the Common Customs Tariff. The duties expressed as percentage rates are to be calculated on the value of the goods as defined in Volume 1 Part 14. In addition, some duties are expressed in European currency the Euro (see paragraph 4.2).

      <b>2.6 - Column 6 - Preferential rates of duty</b>

      Detail of beneficiary countries and county groups is set out in abbreviated form. A key to most of the countries is included on divider cards supplied with the Tariff. A full listing of constituent members of country groups will be found in either Section 6 or Volume 1 Part 7. The duties expressed as percentage rates are to be calculated on the value of the goods as defined in Volume 1 Part 14.

      <b>Note</b>
      <b>In the case of all preferential agreements, where no reduced rate of duty is shown the full rate of duty applies.</b>

      <b>2.7 - Column 7 - VAT rate</b>

      An indication of liability to VAT is provided here (see Volume 1 Part 13). Where goods described in Column 2 may be subject to alternative rates of tax according to elements of description not included specifically in the text for customs duty purposes, all possible VAT rates are shown in column 7. The applicable rate must be determined by reference to VAT leaflets.

      <b>2.8 - Footnotes and end of chapter information</b>

      Where it is not practicable to include information and requirements against the line of the Tariff these are shown as footnotes on the same page or are set out at the end of the Chapter in which they apply under the Commodity Code reference. This additional material has the same legal force as all other information in the Schedule.

      <b>2.9 - Validity of Tariff information</b>

      Every effort is made to include all relevant information and to ensure that changes throught the year are promptly taken account of in the Tariff. The volatile and temporary nature of some tariff measures means that certain changes may occur before detail can be included in the Tariff as an ammendment. Up to date information about tariff changes is available at local customs offices. Alternatively, details are published in the Official Journal of the European Communities.
    CONTENT
  end
end
