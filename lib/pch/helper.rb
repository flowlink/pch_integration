module PCH
  module Helper

    def xml_date(date)
      Date.parse(date).strftime('%F')
    end

    def xml_address_name(address)
      [address['firstname'], address['lastname']].join(' ')
    end

    def xml_address(xml, address)
      xml.Nm1 format(xml_address_name(address))

      xml.Adr1 format(address['address1'])
      xml.Adr2 format(address['address2'])
      xml.City format(address['city'])
      xml.Zip format(address['zipcode'])
      xml.State format(address['state'], 15)
      xml.Ctry format(address['country'])
      xml.Phn format(address['phone'])
      xml.Cont format([address['firstname'], address['lastname']].join(' '))
    end

    def format(value, limit=40)
      value = value.to_s[0..(limit-1)]
      ActiveSupport::Inflector.transliterate value
    end
  end
end
