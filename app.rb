require "sinatra"
require "erb"
require "mysql2"
require "digest"
require "inifile"

ini = IniFile.load "config.ini"
mysql_config = ini["MySQL"]
shortener_config = ini["Shortener"]

mysql = Mysql2::Client.new mysql_config

get "/" do
  redirect "/shorten"
end

get "/shorten" do
  erb :shorten, locals: { title: "Shorten a URL" }
end

post "/shorten" do
  if not request.form_data?
    redirect "/shorten"
  end

  url_escaped = mysql.escape request["url"]
  if not /^(https?:\/\/)?.+\..+$/.match url_escaped
    raise "Invalid URL"
  end
  if not /^https?/.match url_escaped
    url_escaped = "https://" + url_escaped
  end

  id = request["alias"]
  if not id
    id = Digest::SHA2.hexdigest(url_escaped)[0..8]
  end

  begin
    mysql.query "INSERT INTO urls (id, url) VALUES ('#{id}', '#{url_escaped}')"
  rescue
    raise "Couldn't shorten URL"
  end
  erb :shortened, locals: {
    title: "URL shortened",
    short_url: url("/s/" + id)
  }
end

get "/s/:id" do |id|
  id_escaped = mysql.escape id
  r = mysql.query "SELECT url FROM urls WHERE id = '#{id_escaped}'"
  if r.count == 0 then
    pass
  end
  mysql.query "UPDATE urls SET uses = uses + 1 WHERE id = '#{id_escaped}'"
  redirect r.first["url"]
end

not_found do
  code = 404
  erb :error, locals: { code: 404, message: "Not Found" }
end

error do
  erb :error, locals: { message: env["sinatra.error"].message }
end
