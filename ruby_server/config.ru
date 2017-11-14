require 'rubygems'
require 'bundler'

Bundler.require

require './website'
run Sinatra::Application
