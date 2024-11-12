require 'sinatra'

require_relative 'pdf_parser'

set :bind, ENV.fetch('HOST', '0.0.0.0')
set :port, ENV.fetch("PORT", '8081')

get '/healthcheck' do
  'OK'
end

post '/parse' do
  request.body.rewind
  params = JSON.parse(request.body.read, symbolize_names: true)
  pdf_path = params[:path] || params[:id]
  raise "Path is empty" if pdf_path.empty?
  PdfParser.new.parse(pdf_path)
  'OK'
end
