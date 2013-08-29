require './refresh_job'

require 'fog'
require 'dotenv'
require 'twitter'

Dotenv.load unless ENV['RACK_ENV'] == 'production'

Twitter.configure do |config|
  config.consumer_key = ENV['CONSUMER_KEY']
  config.consumer_secret = ENV['CONSUMER_SECRET']
  config.oauth_token = ENV['ACCESS_TOKEN']
  config.oauth_token_secret = ENV['ACCESS_TOKEN_SECRET']
end

storage = Fog::Storage.new(:provider => 'AWS', :aws_access_key_id => ENV['ACCESS_KEY'], :aws_secret_access_key => ENV['SECRET_KEY'])		
$s3 = storage.directories.create(key: ENV['BUCKET'])

get "/#{ENV['ENDPOINT'] || 'test'}" do
	RefreshJob.new.async.perform()
	return "OK"
end

get "/keys" do
	files = $s3.files.map{|file| {key: file.key, modified: file.last_modified}}
	return files.sort_by{|obj|
		-1 * obj[:modified].to_i
	}.map{|file|
		"#{file[:modified]} <a href='https://vong-uopubrecordsreqs.s3.amazonaws.com/#{file[:key]}'>#{file[:key]}</a><br><br>\n"
}
end