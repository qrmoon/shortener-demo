# frozen_string_literal: true

require 'digest'
require 'erb'
require 'inifile'
require 'mysql2'
require 'sinatra'

ini = IniFile.load 'config.ini'
mysql_config = ini['MySQL']

mysql = Mysql2::Client.new mysql_config

get '/' do
  redirect '/shorten'
end

get '/shorten' do
  erb :shorten, locals: { title: 'Shorten a URL' }
end

post '/shorten' do
  redirect '/shorten' unless request.form_data?

  url_escaped = mysql.escape request['url']
  raise 'Invalid URL' unless %r{^(https?://)?.+\..+$}.match url_escaped

  url_escaped = "https://#{url_escaped}" unless /^https?/.match url_escaped

  id = request['alias']
  id ||= Digest::SHA2.hexdigest(url_escaped)[0..8]

  begin
    mysql.query "INSERT INTO urls (id, url) VALUES ('#{id}', '#{url_escaped}')"
  rescue StandardError
    raise "Couldn't shorten URL"
  end
  erb :shortened, locals: {
    title: 'URL shortened',
    short_url: url("/s/#{id}")
  }
end

get '/s/:id' do |id|
  id_escaped = mysql.escape id
  r = mysql.query "SELECT url FROM urls WHERE id = '#{id_escaped}'"
  pass if r.count.zero?
  mysql.query "UPDATE urls SET uses = uses + 1 WHERE id = '#{id_escaped}'"
  redirect r.first['url']
end

not_found do
  erb :error, locals: { code: 404, message: 'Not Found' }
end

error do
  erb :error, locals: { message: env['sinatra.error'].message }
end
