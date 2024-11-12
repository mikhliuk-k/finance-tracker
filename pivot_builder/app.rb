require 'sinatra'

require_relative 'pivot_builder'

set :bind, ENV.fetch('HOST', '0.0.0.0')
set :port, ENV.fetch("PORT", '8080')

get '/healthcheck' do
  'OK'
end

post '/build_pivot' do
  PivotBuilder.new.build_pivot
  'OK'
end
