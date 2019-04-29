require 'uktt'

RSpec.describe 'UK Trade Tariff gem' do
  host = Uktt::API_HOST_PROD

  test_opts = {return_json: false, 
               host: api_host, 
               version: spec_version,
               debug: false}

  new_opts = {host: host,
              version: 'v2',
              return_json: true,
              debug: true}

  section_id = '1'
  section_test = Uktt::Section.new(test_opts.merge(section_id: section_id))

  chapter_id = '01'
  chapter_test = Uktt::Chapter.new(test_opts.merge(chapter_id: chapter_id))

  heading_id = '0101'
  heading_test = Uktt::Heading.new(test_opts.merge(heading_id: heading_id))

  commodity_id = '0101210000'
  commodity_test = Uktt::Commodity.new(test_opts.merge(commodity_id: commodity_id))

  it 'has a version number and is in the correct format' do
    expect(Uktt::VERSION).not_to be(nil)
    expect(Uktt::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it "produces a PDF and saves it in '#{Dir.pwd}'" do
    filepath = Uktt::Pdf.new(chapter_id: 'test').make_chapter
    expect(filepath).to eq("#{Dir.pwd}/test.pdf")
    expect(File.read(filepath)[0, 4]).to eq('%PDF')
    File.delete(filepath) if File.exist?(filepath)
  end

  it 'produces a PDF and saves it at a user-specified filepath' do
    user_filepath = Uktt::Pdf.new(chapter_id: 'test', filepath:'/tmp/test.pdf').make_chapter
    expect(user_filepath).to eq('/tmp/test.pdf')
    expect(File.read(user_filepath)[0, 4]).to eq('%PDF')
    File.delete(user_filepath) if File.exist?(user_filepath)
  end

  it 'sets instance variables on a section' do
    section_test.section_id = '2'
    section_test.config = new_opts

    expect(section_test.section_id).to eq('2')
    expect(section_test.config).to eq(new_opts)
  end

  it 'sets instance variables on a chapter' do
    chapter_test.chapter_id = '02'
    chapter_test.config = new_opts

    expect(chapter_test.chapter_id).to eq('02')
    expect(chapter_test.config).to eq(new_opts)
  end

  it 'sets instance variables on a heading' do
    heading_test.heading_id = '0201'
    heading_test.config = new_opts

    expect(heading_test.heading_id).to eq('0201')
    expect(heading_test.config).to eq(new_opts)
  end

  it 'sets instance variables on a commodity' do
    commodity_test.commodity_id = '0101300000'
    commodity_test.config = new_opts

    expect(commodity_test.commodity_id).to eq('0101300000')
    expect(commodity_test.config).to eq(new_opts)
  end
end
