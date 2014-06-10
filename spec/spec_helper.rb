require 'rubygems'
require 'bundler'
require 'hub/samples'

Bundler.require(:default, :test)

ENV['ENDPOINT_KEY'] = 'x123'
require File.join(File.dirname(__FILE__), '..', 'pch_endpoint.rb')

Sinatra::Base.environment = 'test'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
end

def app
  PCHEndpoint
end

module PCH
  module SpecHelpers
    def self.included(base)
      base.let(:shipment) do
        shipment = Hub::Samples::Shipment.object['shipment']
        shipment['billing_address'] = shipment['shipping_address']

        shipment['items'] = [
          {
            "name" => "Spree T-Shirt",
            "variant_id" => "32",
            "quantity" => 1,
            "price" => 30.0,
            "product_id" => "650-0120",
            "options" => {
            }
          }
        ]

        shipment["ship_condition"] = "WE"
        shipment["ship_carrier"] = "UPS"

        shipment
      end

      base.let(:auth) {
        {'HTTP_X_HUB_TOKEN' => '532c76b6b4395730e7038754', "CONTENT_TYPE" => "application/json"}
      }

    end
  end
end

# support/global_helpers.rb
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include PCH::SpecHelpers
end

