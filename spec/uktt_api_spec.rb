require 'uktt'

RSpec.describe 'UK Trade Tariff API client' do
  opts = {host: api_host, 
          version: spec_version, 
          debug: false,
          format: 'ostruct'}

  section_id = '1'
  section = Uktt::Section.new(opts.merge(section_id: section_id))

  chapter_id = '01'
  chapter = Uktt::Chapter.new(opts.merge(chapter_id: chapter_id))

  heading_id = '0101'
  heading = Uktt::Heading.new(opts.merge(heading_id: heading_id))

  commodity_id = '0101210000'
  commodity = Uktt::Commodity.new(opts.merge(commodity_id: commodity_id))

  monetary_exchange_rate = Uktt::MonetaryExchangeRate.new(opts)

  quota = Uktt::Quota.new(opts)
  quota_search_params = {
    goods_nomenclature_item_id: '0805102200',
    year: '2018',
    geographical_area_id: 'EG',
    order_number: '091784',
    status: 'not_blocked'
  }

  it 'retrieves one section as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = section.retrieve

    expect(response).to be_an_instance_of(OpenStruct)
    case spec_version
    when 'v1'
      expect(response.position.to_s).to eq(section_id)
    when 'v2'
      expect(response.data.attributes.position.to_s).to eq(section_id)
    end
  end

  it 'retrieves one section as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(section.retrieve, symbolize_names: true)

    expect(response).to be_an_instance_of(Hash)
    case spec_version
    when 'v1'
      expect(response[:position].to_s).to eq(section_id)
    when 'v2'
      expect(response[:data][:attributes][:position].to_s).to eq(section_id)
    end
  end

  it 'retrieves one section\'s note as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = section.note

    expect(response).to be_an_instance_of(OpenStruct)
    case spec_version
    when 'v1'
      expect(response.section_id.to_s).to eq(section_id)
    when 'v2'
      expect(response.section_id.to_s).to eq(section_id)
    end
  end

  it 'retrieves one section\'s note as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(section.note, symbolize_names: true)

    expect(response).to be_an_instance_of(Hash)
    case spec_version
    when 'v1'
      expect(response[:section_id].to_s).to eq(section_id)
    when 'v2'
      expect(response[:section_id].to_s).to eq(section_id)
    end
  end

  it 'retrieves all sections as [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = section.retrieve_all

    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq(21)
    when 'v2'
      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.length).to eq(21)
      expect(response.data.first).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes.position).to eq(1)
    end
  end

  it 'retrieves all sections as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(section.retrieve_all, symbolize_names: true)

    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq(21)
    when 'v2'
      expect(response[:data]).to be_an_instance_of(Array)
      expect(response[:data].length).to eq(21)
    end
  end

  it 'retrieves one chapter as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = chapter.retrieve

    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.goods_nomenclature_item_id).to eq("#{chapter_id}00000000")
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data.attributes.goods_nomenclature_item_id).to eq("#{chapter_id}00000000")
    end
  end

  it 'retrieves one chapter as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(chapter.retrieve, symbolize_names: true)

    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
    when 'v2'
      expect(response[:data][:attributes]).to be_an_instance_of(Hash)
      expect(response[:data][:attributes][:goods_nomenclature_item_id]).to eq("#{chapter_id}00000000")
    end
  end
  
  it 'retrieves one chapter\'s note as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = chapter.note

    expect(response).to be_an_instance_of(OpenStruct)
    case spec_version
    when 'v1'
      expect(response.section_id.to_s).to eq(section_id)
      expect(response.chapter_id).to eq(chapter_id)
    when 'v2'
      expect(response.section_id.to_s).to eq(section_id)
      expect(response.chapter_id).to eq(chapter_id)
    end
  end

  it 'retrieves one chapter\'s note as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(chapter.note, symbolize_names: true)

    case spec_version
    when 'v1'
      expect(response[:section_id].to_s).to eq(section_id)
      expect(response[:chapter_id]).to eq(chapter_id)
    when 'v2'
      expect(response[:section_id].to_s).to eq(section_id)
      expect(response[:chapter_id]).to eq(chapter_id)
    end
  end

  it 'retrieves one chapter\'s changes as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = chapter.changes
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to respond_to(:oid)
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:oid)
    end
  end

  it 'retrieves one chapter\'s changes as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(chapter.changes, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to have_key(:oid)
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes]).to have_key(:oid)
    end
  end

  it 'retrieves all chapters as [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = chapter.retrieve_all
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq(98)
    when 'v2'
      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.length).to eq(98)
      expect(response.data.first).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes.goods_nomenclature_item_id).to eq('0100000000')
    end
  end

  it 'retrieves all chapters as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(chapter.retrieve_all, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.length).to eq(98)
    when 'v2'
      expect(response[:data]).to be_an_instance_of(Array)
      expect(response[:data].length).to eq(98)
    end
  end

  it 'retrieves one heading as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = heading.retrieve
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.goods_nomenclature_item_id).to eq("#{heading_id}000000")
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data.attributes.goods_nomenclature_item_id).to eq("#{heading_id}000000")
    end
  end

  it 'retrieves one heading as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(heading.retrieve, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data][:attributes][:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
    end
  end

  it 'retrieves one heading\'s changes as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = heading.changes
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to respond_to(:oid)
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:oid)
    end
  end

  it 'retrieves one heading\'s changes as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(heading.changes, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to have_key(:oid)
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes]).to have_key(:oid)
    end
  end

  it 'retrieves one commodity as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = commodity.retrieve
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.goods_nomenclature_item_id).to eq(commodity_id)
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data.attributes.goods_nomenclature_item_id).to eq(commodity_id)
    end
  end

  it 'retrieves one commodity as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(commodity.retrieve, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:goods_nomenclature_item_id]).to eq(commodity_id)
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data][:attributes][:goods_nomenclature_item_id]).to eq(commodity_id)
    end
  end

  it 'retrieves one commodity\'s changes as OpenStruct' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = commodity.changes
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to respond_to(:oid)
    when 'v2'
      expect(response).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:oid)
    end
  end

  it 'retrieves one commodity\'s changes as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(chapter.changes, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to have_key(:oid)
    when 'v2'
      expect(response).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes]).to have_key(:oid)
    end
  end

  it 'retrieves monetary exchange rates as [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    response = monetary_exchange_rate.retrieve_all
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to be_an_instance_of(OpenStruct)
      expect(response.first).to respond_to(:exchange_rate)
    when 'v2'
      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.first).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:exchange_rate)
    end
  end

  it 'retrieves monetary exchange rates as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    response = JSON.parse(monetary_exchange_rate.retrieve_all, symbolize_names: true)
    case spec_version
    when 'v1'
      expect(response).to be_an_instance_of(Array)
      expect(response.first).to be_an_instance_of(Hash)
      expect(response.first).to have_key(:exchange_rate)
    when 'v2'
      expect(response[:data]).to be_an_instance_of(Array)
      expect(response[:data].first).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes]).to have_key(:exchange_rate)
    end
  end

  it 'retrieves goods nomenclatures for a heading as [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    case spec_version
    when 'v2'
      response = heading.goods_nomenclatures

      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.first).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:goods_nomenclature_item_id)
    end
  end

  it 'retrieves goods nomenclatures for a heading as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    case spec_version
    when 'v2'
      response = JSON.parse(heading.goods_nomenclatures, symbolize_names: true)

      expect(response).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes][:goods_nomenclature_item_id]).to eq("#{heading_id}000000")
    end
  end

  it 'retrieves goods nomenclatures for a chapter as [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    case spec_version
    when 'v2'
      response = chapter.goods_nomenclatures

      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.first).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:goods_nomenclature_item_id)
    end
  end

  it 'retrieves goods nomenclatures for a chapter as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    case spec_version
    when 'v2'
      response = JSON.parse(chapter.goods_nomenclatures, symbolize_names: true)

      expect(response).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes][:goods_nomenclature_item_id][0..1]).to eq(chapter_id)
    end
  end

  it 'retrieves goods nomenclatures for a section as [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    case spec_version
    when 'v2'
      response = section.goods_nomenclatures

      expect(response.data).to be_an_instance_of(Array)
      expect(response.data.first).to be_an_instance_of(OpenStruct)
      expect(response.data.first.attributes).to respond_to(:goods_nomenclature_item_id)
    end
  end

  it 'retrieves goods nomenclatures for a section as JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    case spec_version
    when 'v2'
      response = JSON.parse(section.goods_nomenclatures, symbolize_names: true)

      expect(response).to be_an_instance_of(Hash)
      expect(response[:data].first[:attributes][:goods_nomenclature_item_id]).to be_an_instance_of(String)
    end
  end

  it 'performs a search and returns [OpenStructs]' do
    Uktt.configure(format: 'ostruct', version: spec_version)
    case spec_version
    when 'v2'
      response = quota.search(quota_search_params)

      expect(response.data.first.attributes.quota_order_number_id).to eq(quota_search_params[:order_number])
    end
  end

  it 'performs a search and returns JSON' do
    Uktt.configure(format: 'json', version: spec_version)
    case spec_version
    when 'v2'
      response = JSON.parse(quota.search(quota_search_params), symbolize_names: true)

      expect(response[:data].first[:attributes][:quota_order_number_id]).to eq(quota_search_params[:order_number])
    end
  end
end
