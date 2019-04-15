require 'uktt'

RSpec.describe 'UK Trade Tariff API client' do
  host = Uktt::API_HOST_LOCAL
  production_host = Uktt::API_HOST_PROD
  version = Uktt::API_VERSION

  section_id = '1'
  section = Uktt::Section.new(section_id)
  section_json = Uktt::Section.new(section_id, true)
  # section_production = Uktt::Section.new(section_id, false, production_host, 'v1')
  section_test = Uktt::Section.new(section_id, false, 'foo', 'v1')

  chapter_id = '01'
  chapter = Uktt::Chapter.new(chapter_id)
  chapter_json = Uktt::Chapter.new(chapter_id, true)
  # chapter_production = Uktt::Chapter.new(chapter_id, false, production_host, 'v1')
  chapter_test = Uktt::Chapter.new(chapter_id, false, 'foo', 'v1')

  heading_id = '0101'
  heading = Uktt::Heading.new(heading_id)
  heading_json = Uktt::Heading.new(heading_id, true)
  # heading_production = Uktt::Heading.new(heading_id, false, production_host, 'v1')
  heading_test = Uktt::Heading.new(heading_id, false, 'foo', 'v1')

  commodity_id = '0101210000'
  commodity = Uktt::Commodity.new(commodity_id)
  commodity_json = Uktt::Commodity.new(commodity_id, true)
  # commodity_production = Uktt::Commodity.new(commodity_id, false, production_host, 'v1')
  commodity_test = Uktt::Commodity.new(commodity_id, false, 'foo', 'v1')

  it "has a version number and is in the correct format" do
    expect(Uktt::VERSION).not_to be(nil)
    expect(Uktt::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it 'sets the @host instance variable on a section' do
    section_test.host = host
    expect(section_test.host).to eq(host)
  end

  it 'sets the @version instance variable on a section' do
    section_test.version = 'v2'
    expect(section_test.version).to eq('v2')
  end

  it 'sets the @section_id instance variable on a section' do
    section_test.section_id = '2'
    expect(section_test.section_id).to eq('2')
  end

  it 'sets the @return_json instance variable on a section' do
    section_test.return_json = true
    expect(section_test.return_json).to eq(true)
  end

  it 'sets the @debug instance variable on a section' do
    section_test.debug = true
    expect(section_test.debug).to eq(true)
  end

  it 'sets the @host instance variable on a chapter' do
    chapter_test.host = host
    expect(chapter_test.host).to eq(host)
  end

  it 'sets the @version instance variable on a chapter' do
    chapter_test.version = 'v2'
    expect(chapter_test.version).to eq('v2')
  end

  it 'sets the @chapter_id instance variable on a chapter' do
    chapter_test.chapter_id = '02'
    expect(chapter_test.chapter_id).to eq('02')
  end

  it 'sets the @return_json instance variable on a chapter' do
    chapter_test.return_json = true
    expect(chapter_test.return_json).to eq(true)
  end

  it 'sets the @debug instance variable on a chapter' do
    chapter_test.debug = true
    expect(chapter_test.debug).to eq(true)
  end

  it 'sets the @host instance variable on a heading' do
    heading_test.host = host
    expect(heading_test.host).to eq(host)
  end

  it 'sets the @version instance variable on a heading' do
    heading_test.version = 'v2'
    expect(heading_test.version).to eq('v2')
  end

  it 'sets the @heading_id instance variable on a heading' do
    heading_test.heading_id = '0201'
    expect(heading_test.heading_id).to eq('0201')
  end

  it 'sets the @return_json instance variable on a heading' do
    heading_test.return_json = true
    expect(heading_test.return_json).to eq(true)
  end

  it 'sets the @debug instance variable on a heading' do
    heading_test.debug = true
    expect(heading_test.debug).to eq(true)
  end

  it 'sets the @host instance variable on a commodity' do
    commodity_test.host = host
    expect(commodity_test.host).to eq(host)
  end

  it 'sets the @version instance variable on a commodity' do
    commodity_test.version = 'v2'
    expect(commodity_test.version).to eq('v2')
  end

  it 'sets the @commodity_id instance variable on a commodity' do
    commodity_test.commodity_id = asses = '0101300000'
    expect(commodity_test.commodity_id).to eq(asses)
  end

  it 'sets the @return_json instance variable on a commodity' do
    commodity_test.return_json = true
    expect(commodity_test.return_json).to eq(true)
  end

  it 'sets the @debug instance variable on a commodity' do
    commodity_test.debug = true
    expect(commodity_test.debug).to eq(true)
  end

  it "retrieves one section as OpenStruct" do
    response = section.retrieve
    expect(response).to be_an_instance_of(OpenStruct)
    expect(response.position.to_s).to eq(section_id)
  end

  # it "retrieves one section as OpenStruct from PRODUCTION V1" do
  #   response = section_production.retrieve
  #   expect(response).to be_an_instance_of(OpenStruct)
  #   expect(response.position.to_s).to eq(section_id)
  # end

  it "retrieves one section as JSON" do
    response = JSON.parse(section_json.retrieve, symbolize_names: true)
    expect(response).to be_an_instance_of(Hash)
    expect(response[:position].to_s).to eq(section_id)
  end

  it "retrieves all sections as [OpenStructs]" do
    response = section.retrieve_all
    expect(response).to be_an_instance_of(Array)
    expect(response.length).to eq( 21 )
  end

  it "retrieves all sections as JSON" do
    response = JSON.parse(section_json.retrieve_all, symbolize_names: true)
    expect(response).to be_an_instance_of(Array)
    expect(response.length).to eq( 21 )
  end

  it "retrieves one chapter as OpenStruct" do
    response = chapter.retrieve
    expect(response).to be_an_instance_of(OpenStruct)
    expect(response[:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
  end

  # it "retrieves one chapter as OpenStruct from PRODUCTION V1" do
  #   response = chapter_production.retrieve
  #   expect(response).to be_an_instance_of(OpenStruct)
  #   expect(response.goods_nomenclature_item_id).to eq("#{chapter_id}00000000")
  # end

  it "retrieves one chapter as JSON" do
    response = JSON.parse(chapter_json.retrieve, symbolize_names: true)
    expect(response).to be_an_instance_of(Hash)
    expect(response[:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
  end

  it "retrieves all chapters as [OpenStructs]" do
    response = chapter.retrieve_all
    expect(response).to be_an_instance_of(Array)
    expect(response.length).to eq( 98 )
  end

  it "retrieves all chapters as JSON" do
    response = JSON.parse(chapter_json.retrieve_all, symbolize_names: true)
    expect(response).to be_an_instance_of(Array)
    expect(response.length).to eq( 98 )
  end

  it "retrieves one heading as OpenStruct" do
    response = heading.retrieve
    expect(response).to be_an_instance_of(OpenStruct)
    expect(response[:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
  end

  # it "retrieves one heading as OpenStruct from PRODUCTION V1" do
  #   response = heading_production.retrieve
  #   expect(response).to be_an_instance_of(OpenStruct)
  #   expect(response.goods_nomenclature_item_id).to eq("#{heading_id}000000")
  # end

  it "retrieves one heading as JSON" do
    response = JSON.parse(heading_json.retrieve, symbolize_names: true)
    expect(response).to be_an_instance_of(Hash)
    expect(response[:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
  end

  it "retrieves one commodity as OpenStruct" do
    response = commodity.retrieve
    expect(response).to be_an_instance_of(OpenStruct)
    expect(response[:goods_nomenclature_item_id]).to eq(commodity_id)
  end

  # it "retrieves one commodity as OpenStruct from PRODUCTION V1" do
  #   response = commodity_production.retrieve
  #   expect(response).to be_an_instance_of(OpenStruct)
  #   expect(response.goods_nomenclature_item_id).to eq(commodity_id)
  # end

  it "retrieves one commodity as JSON" do
    response = JSON.parse(commodity_json.retrieve, symbolize_names: true)
    expect(response).to be_an_instance_of(Hash)
    expect(response[:goods_nomenclature_item_id]).to eq(commodity_id)
  end
end
