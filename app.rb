require './refresh_job'
require 'fog'
require 'dotenv'
require 'twitter'

Dotenv.load unless ENV['RACK_ENV'] == 'production'

$connection = Fog::Storage.new(:provider => 'AWS', :aws_access_key_id => ENV['ACCESS_KEY'], :aws_secret_access_key => ENV['SECRET_KEY'])		
$s3 = $connection.directories.create(key: ENV['BUCKET'], public: true)

get "/#{ENV['ENDPOINT'] || 'test'}" do
	RefreshJob.new.async.perform()
	return "OK"
end

get "/keys" do
	$s3.files.map{|file| 		
		{key: file.key, modified: file.last_modified}
	}.sort_by{|obj|
		-1 * obj[:modified].to_i
	}.map{|file|
		"#{file[:modified]} <a href='https://uopublicrecords.s3.amazonaws.com/#{file[:key]}'>#{file[:key]}</a><br><br>\n"
	}
end

get '/rescue-some-shit-yo' do
	# most helpful docs were the source for me: https://github.com/fog/fog/blob/master/lib/fog/aws/models/storage/file.rb
	options = {
		'x-amz-acl' => 'public-read', # i forgot this the first time and made everything private :(
		'x-amz-metadata-directive' => 'REPLACE',
		'Content-Type' => 'text/html'
	}
	requests = 0
	$s3.files.each do |file|
		content_type = $s3.files.head(file.key).content_type
		requests += 1
		unless content_type == "text/html"
			copy_result = file.copy(ENV['BUCKET'], file.key, options)
			requests += 1
			puts "file.copy complete for #{file.directory} / #{file.key}, (#{content_type}), result:#{copy_result}"
		end
	end
	requests.to_s # sinatra will think it's a HTTP status code if it's an integer
end
