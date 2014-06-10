require 'spec_helper'

describe PCHEndpoint do
  let(:base) {
    {
      request_id: '123',
      parameters: {
        'pch_url' => 'https://dataflo2.pchqas.com/B2B/Generic'
      }
    }
  }

  context '/add_shipment' do
    let(:payload) do
      base[:shipment] = shipment
      base
    end

    it 'sends a DO to PCH, and reports success' do

      VCR.use_cassette('pch_delivery_order') do
        post '/add_shipment', payload.to_json, auth

        last_response.status.should == 200
        response = JSON.parse(last_response.body)
        response['summary'].should == "Shipment 12836 was sent to PCH."
      end
    end

    it 'reports failure when sending the DO fails' do
      VCR.use_cassette('pch_delivery_order_failure') do
        post '/add_shipment', payload.to_json, auth

        last_response.status.should == 500
        response = JSON.parse(last_response.body)
        response['summary'].should == "Failed to send shipment 12836 to PCH."
        response['pch_response'].should match /An error occured while processing the delivery orders. No delivery orders have been created.\nOrder H438105531460 could not be processed./
      end
    end
  end

  context '/get_shipments' do
    let(:payload) do
      base[:parameters]['pch_next_sc_token'] = ''
      base
    end

    it 'fetches shipped shipments from PCH' do
      VCR.use_cassette('pch_shipping_confirmation') do
        post '/get_shipments', payload.to_json, auth

        last_response.status.should == 200
        response = JSON.parse(last_response.body)
        response['shipments'].size.should == 1

        shipment = response['shipments'].first
        shipment['shipped_at'].should == "2012-11-30 00:00:00 UTC"
        pch_item = shipment['pch_items'].first
        pch_item['part_number'].should == "SamplePN1"
        pch_item['quantity'].should == 192
        pch_item['serial_numbers'].split(',').size.should == 188
      end
    end
  end

  context '/get_inventory' do
    let(:payload) do
      base[:parameters]['pch_next_gan_token'] = ''
      base
    end

    it 'fetches shipped shipments from PCH' do
      VCR.use_cassette('pch_goods_available_notice') do
        post '/get_inventory', payload.to_json, auth

        last_response.status.should == 200
        response = JSON.parse(last_response.body)
        response['inventories'].size.should == 15

        inventory = response['inventories'].first
        inventory['product_id'].should == 'LB-BIT-o13-FAN-v03-2'
        inventory['quantity'].should == 1_000
        inventory['token'].should == ""
      end
    end
  end
end
