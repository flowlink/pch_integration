require 'spec_helper'

describe PCH::DeliveryOrder do

  subject { described_class }

  context "#xml_payload" do

    it 'builds basic XML from the shipment object' do
      xml = subject.xml_payload(shipment)
      doc = Nokogiri::XML(xml)

      xml.should match "<DN>12836</DN>"
      xml.should match "<Car>UPS</Car>"
      xml.should match "<Con>WE</Con>"

      doc.search('Itm').size.should == 1

      itm = doc.at('Itm')
      itm.at('LN').text.should == '32'
      itm.at('Qty').text.should == '1'
      itm.at('PN').text.should == '650-0120'
      itm.at('Prc').text.should == '30.0'
    end

    it 'should include `customer_group` as `CG`' do
      shipment['customer_group'] = 'B2C'

      xml = subject.xml_payload(shipment)
      xml.should match "<CG>B2C</CG>"
    end

    it 'should include `ship_condition` as `Con`' do
      shipment['ship_condition'] = 'WS'

      xml = subject.xml_payload(shipment)
      xml.should match "<Con>WS</Con>"
    end

    it 'should include `po_number` as `PO`' do
      shipment['po_number'] = 'ABC-123'

      xml = subject.xml_payload(shipment)
      xml.should match "<PO>ABC-123</PO>"
    end

    #it 'should include `carrier_account_number` as `Con`' do
      #shipment['ship_condition'] = 'GND'
      #shipment['ship_carrier'] = 'Local'
      #shipment['carrier_account_number'] = 'A49HF934'

      #xml = subject.xml_payload(shipment)
      #xml.should match "<Con>GND</Con>"
      #xml.should match "<Car>Local</Car>"
      #xml.should match "<CarAc>A49HF934</CarAc>"
    #end

    it 'should include `SI` fields if `sop_code` is present' do
      shipment['sop_code'] = 'SOP-23432'

      xml = subject.xml_payload(shipment)
      doc = Nokogiri::XML(xml)
      doc.search('SI').size.should == 1
      doc.at('SI').each_with_index do |si ,i|
        si.at('Tp').text.should == 'SOP'
        si.at('Ln').text.should == 1
        si.at('Msg').text.should == 'SOP-23432'
      end
    end

    it 'should include `SI` fields if `gift_wrap` is true' do
      shipment['gift_wrap_code'] = 'AB-123'

      xml = subject.xml_payload(shipment)
      doc = Nokogiri::XML(xml)
      doc.search('SI').size.should == 1
      doc.at('SI').each_with_index do |si ,i|
        si.at('Tp').text.should == 'GP'
        si.at('Ln').text.should == 1
        si.at('Msg').text.should == 'AB-123'
      end
    end

    it 'should include `SI` fields if `special_instructions` is a non-empty array' do
      shipment['special_instructions'] = ['Dear Ndugu,', 'Here are some littleBits', 'enjoy']

      xml = subject.xml_payload(shipment)
      doc = Nokogiri::XML(xml)
      doc.search('SI').size.should == 3
      doc.at('SI').each_with_index do |si ,i|
        si.at('Tp').text.should == 'CMsg'
        si.at('Ln').text.should == i + 1
        si.at('Msg').text.should == args['special_instrucions'][i]
      end
    end

  end
end
