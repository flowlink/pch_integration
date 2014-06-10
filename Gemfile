source 'https://rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'httparty'
gem 'savon'
gem 'nokogiri'
gem 'activesupport'

group :test do
  gem 'vcr'
  gem 'rspec'
  gem 'webmock', '1.8.0'
  gem 'guard-rspec'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rack-test'
  gem 'hub_samples', github: 'spree/hub_samples'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end

group :development do
  gem 'capistrano'
  gem 'byebug'
end

gem 'endpoint_base', github: 'spree/endpoint_base'
gem 'honeybadger'
