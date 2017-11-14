require 'rubygems'
require 'bundler/setup'

require 'sinatra'

get '/' do
  'Hello world! :D'
end

get '/:text' do
    "Hello there, I see you are accessing #{params['text']}"
end
