module PCH
  module DeliveryOrder
    extend Helper

    def self.successful?(response)
      response.body[:create_delivery_orders_response][:create_delivery_orders_result][:outcome] == 'Completed'
    end

    def self.xml_payload(shipment)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.DeliveryOrders('Action' => 'Create',
                           'xsi:noNamespaceSchemaLocation' => 'http://schema.pchintl.com/DO/DO_1.0.xsd',
                           'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
          xml.DO {
            xml.DN shipment['id']
            #TODO remove fallback
            xml.PODT Date.parse( shipment['created_at'] || Time.now.utc.to_s ).strftime('%F')
            xml.DCDT Date.parse( shipment['completed_at'] || Time.now.utc.to_s ).strftime('%F')
            xml.CG shipment['customer_group']
            xml.PO shipment['po_number'] if shipment['po_number'].present?

            xml.BAdr {
              xml_address(xml, shipment['billing_address'])
            }
            xml.SAdr {
              xml_address(xml, shipment['shipping_address'])
            }

            xml.Ship {
              xml.Car shipment['ship_carrier']
              xml.Con shipment['ship_condition']
            }

            shipment['items'].each do |item|
              xml.Itm {
                xml.LN item['variant_id']
                xml.Qty item['quantity']
                xml.PN item['product_id']
                xml.Prc item['price']
                xml.UOM 'EA'
              }
            end

            if shipment['gift_wrap_code'].present?
              xml.SI {
                xml.Tp 'GP'
                xml.Ln 1
                xml.Msg shipment['gift_wrap_code']
              }
            end

            if shipment['sop_code'].present?
              xml.SI {
                xml.Tp 'SOP'
                xml.Ln 1
                xml.Msg shipment['sop_code']
              }
            end

            shipment['special_instructions'] ||= []
            shipment['special_instructions'].each_with_index do |si, i|
              xml.SI {
                xml.Tp 'CMsg'
                xml.Ln i + 1
                xml.Msg si
              }
            end
          }
        }
      end
      return builder.to_xml
    end
  end
end
