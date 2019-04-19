require 'uktt'

RSpec.describe 'UK Trade Tariff API client' do
  host = Uktt::API_HOST_LOCAL
  production_host = Uktt::API_HOST_PROD
  version = Uktt::API_VERSION

  section_id = '1'
  section = Uktt::Section.new(section_id, false, get_host, spec_version)
  section_json = Uktt::Section.new(section_id, true)

  chapter_id = '01'
  chapter = Uktt::Chapter.new(chapter_id, false, get_host, spec_version)
  chapter_json = Uktt::Chapter.new(chapter_id, true)

  heading_id = '0101'
  heading = Uktt::Heading.new(heading_id, false, get_host, spec_version)
  heading_json = Uktt::Heading.new(heading_id, true)

  commodity_id = '0101210000'
  commodity = Uktt::Commodity.new(commodity_id, false, get_host, spec_version)
  commodity_json = Uktt::Commodity.new(commodity_id, true)

  it "retrieves one section as OpenStruct" do
    response = section.retrieve
    expect(response).to be_an_instance_of(OpenStruct)
    case spec_version
    when 'v1'
      expect(response.position.to_s).to eq(section_id)
    when 'v2'
      expect(response.data[:attributes][:position].to_s).to eq(section_id)
    end
  end

  it "retrieves one section as JSON" do
    response = JSON.parse(section_json.retrieve, symbolize_names: true)
    expect(response).to be_an_instance_of(Hash)
    case spec_version
    when 'v1'
      expect(response[:position].to_s).to eq(section_id)
    when 'v2'
      expect(response[:data][:attributes][:position].to_s).to eq(section_id)
    end

  end

  it "retrieves all sections as [OpenStructs]" do
    response = section.retrieve_all
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq( 21 )
    when 'v2'
      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.length).to eq( 21 )
    end
  end

  it "retrieves all sections as JSON" do
    response = JSON.parse(section_json.retrieve_all, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq( 21 )
    when 'v2'
      expect(response[:data]).to be_an_instance_of(Array)
      expect(response[:data].length).to eq( 21 )
    end
  end

  it "retrieves one chapter as OpenStruct" do
    response = chapter.retrieve
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.goods_nomenclature_item_id).to eq("#{chapter_id}00000000")
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data[:attributes][:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
    end
  end

  it "retrieves one chapter as JSON" do
    response = JSON.parse(chapter_json.retrieve, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
    when 'v2'
      expect(response[:data][:attributes]).to be_an_instance_of(Hash)
      expect(response[:data][:attributes][:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
    end
  end

  it "retrieves all chapters as [OpenStructs]" do
    response = chapter.retrieve_all
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq( 98 )
    when 'v2'
      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.length).to eq( 98 )
    end
  end

  it "retrieves all chapters as JSON" do
    response = JSON.parse(chapter_json.retrieve_all, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq( 98 )
    when 'v2'
      expect(response[:data]).to be_an_instance_of(Array)
      expect(response[:data].length).to eq( 98 )
    end
  end

  it "retrieves one heading as OpenStruct" do
    response = heading.retrieve
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.goods_nomenclature_item_id).to eq("#{heading_id}000000")
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data[:attributes][:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
    end
  end

  it "retrieves one heading as JSON" do
    response = JSON.parse(heading_json.retrieve, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data][:attributes][:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
    end
  end

  it "retrieves one commodity as OpenStruct" do
    response = commodity.retrieve
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.goods_nomenclature_item_id).to eq(commodity_id)
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data[:attributes][:goods_nomenclature_item_id]).to eq(commodity_id)
    end
  end

  it "retrieves one commodity as JSON" do
    response = JSON.parse(commodity_json.retrieve, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:goods_nomenclature_item_id]).to eq(commodity_id)
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data][:attributes][:goods_nomenclature_item_id]).to eq(commodity_id)
    end
  end
end
