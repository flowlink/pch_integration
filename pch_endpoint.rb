require File.expand_path(File.dirname(__FILE__) + '/lib/pch/helper')
Dir['./lib/**/*.rb'].each { |f| require f }

class PCHEndpoint < EndpointBase::Sinatra::Base
  endpoint_key '532c76b6b4395730e7038754'

  Honeybadger.configure do |config|
    config.api_key = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end

  set :logging, true

  before do
    @config ||= {}
    @sender_id = @config['pch_sender_id']
    @check_string = @config['pch_check_string']
    @company_id = @config['pch_company_id']
  end

  post '/add_shipment' do
    @shipment = @payload['shipment']
    client = client("/DO.asmx?WSDL")

    xml_body = { message: { senderID:     @sender_id,
             checkString:  @check_string,
             companyID:    @company_id,
             xmlPayload:   PCH::DeliveryOrder.xml_payload(@shipment) } }
    response = client.call :create_delivery_orders, xml_body

    if PCH::DeliveryOrder.successful?(response)
      set_summary "Shipment #{@shipment[:id]} was sent to PCH."
      process_result 200

    else
      set_summary "Failed to send shipment #{@shipment[:id]} to PCH."
      add_value :pch_response, (response.body[:create_delivery_orders_response][:create_delivery_orders_result][:msg] rescue 'unknown')

      process_result 500
    end
  end

  post '/get_shipments' do
    @next_sc_token = @config['pch_next_sc_token'] || ''

    client = client("/SC.asmx?WSDL")

    xml_body = { message: { senderID:     @sender_id,
             checkString:  @check_string,
             companyID:    @company_id,
             nextToken:    @next_sc_token } }

    begin
      response = client.call :get_shipment_confirmations_by_next_token, xml_body

      result = response.body[:get_shipment_confirmations_by_next_token_response][:get_shipment_confirmations_by_next_token_result]
      doc = Nokogiri::XML result[:xml]

      doc.xpath('//SC').each do |sc|
        shipment_number = sc.xpath('DN').text
        tracking = sc.xpath('Cnt/TrkNm').to_a.map(&:text)
        shipped_at = Time.parse(sc.xpath('ShDt').text).utc

        items = []
        sc.xpath('Cnt/Itm').each do |itm|
          items << { part_number: itm.xpath('PN').text,
                     quantity: itm.xpath('Qty').text.to_i,
                     serial_numbers: itm.xpath('SN').to_a.map(&:text).join(',') }
        end

        add_object :shipment, { id: shipment_number,
                                status: 'shipped',
                                shipped_at: shipped_at,
                                tracking: tracking,
                                pch_items: items }

      end

      add_parameter 'pch_next_sc_token', result[:next_token]

      process_result 200
    rescue Exception => e

      set_summary "Failed to fetch shipment confirmations from PCH."
      add_value :exception, e.message
      add_value :backtrace, e.backtrace

      process_result 500
    end

  end

  post '/get_inventory' do
    @next_gan_token = @config['pch_next_gan_token'] || ''

    client = client("/GAN.asmx?WSDL")

    xml_body = { message: { senderID:     @sender_id,
             checkString:  @check_string,
             companyID:    @company_id,
             nextToken:    @next_gan_token } }

    begin
      response = client.call :get_goods_arrival_notices_by_next_token, xml_body
      result = response.body[:get_goods_arrival_notices_by_next_token_response][:get_goods_arrival_notices_by_next_token_result]
      doc = Nokogiri::XML result[:xml]

      doc.xpath('//GA').each do |ga|
        token = ga.xpath("Token").text

        ga.xpath('Itm').each do |item|
          product_id = item.xpath('PN').text
          add_object :inventory, { id: "#{product_id}-#{token}",
                                   product_id: product_id,
                                   location: 'PCH',
                                   quantity: item.xpath('Qty').text.to_i,
                                   token: token }
        end
      end

      add_parameter 'pch_next_gan_token', result[:next_token]
      process_result 200
    rescue Exception => e

      set_summary "Failed to fetch goods available notices from PCH."
      add_value :exception, e.message
      add_value :backtrace, e.backtrace

      process_result 500
    end
  end

  private

  def client(wsdl)
    Savon.client(wsdl: @config['pch_url'] + wsdl)
  end

end
