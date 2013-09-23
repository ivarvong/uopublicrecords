require 'httparty'
require 'celluloid/autostart'
require 'dotenv'
require 'fog'
require 'nokogiri'
require 'json'
Dotenv.load unless ENV['RACK_ENV'] == 'production'

class Downloader
	include Celluloid
	def download(url)		
		html = HTTParty.get(url)
		{url: url, doc: Nokogiri::HTML(html)}
	end	
end

def make_ascii(raw)
	# See String#encode. Thanks to http://stackoverflow.com/questions/1268289/how-to-get-rid-of-non-ascii-characters-in-ruby for this
	encoding_options = {
		:invalid           => :replace,  # Replace invalid byte sequences
		:undef             => :replace,  # Replace anything not defined in ASCII
		:replace           => ' ',        # Use a blank for those replacements
		:universal_newline => false       # Always break lines with \n
	}
	raw.encode(Encoding.find('ASCII'), encoding_options)
end

puts "Connecting to S3..."
connection = Fog::Storage.new(provider: 'AWS', aws_access_key_id: ENV['ACCESS_KEY'], aws_secret_access_key: ENV['SECRET_KEY'])
directory = connection.directories.create(key: ENV['BUCKET'], public: true)

puts "Building file list..."
urls = directory.files.map{ |file| 
	if file.key.include?('original/') # this could be a one-liner
		"http://#{ENV['BUCKET']}.s3.amazonaws.com/#{file.key}" 
	else
		nil
	end
}.compact

puts "Downloading #{urls.count} files..." 
download_pool = Downloader.pool(size: 200) # Downloading from S3 is likely IO-bound... which is why this pool big, and why MRI is okay

#urls = urls.take(10) # debug mode ;)

files = urls.map{ |url| 
	download_pool.future.download(url) # This is the magic of celluloid
}.map(&:value) 

puts "Processing files..."
final = files.map do |file|
	
	slug, revision = file[:url].split("/original/")[1..-1].first.split("/") # this is totally implmentation-specific. and ugly.
	doc = file[:doc]
	title =   make_ascii(doc.css('h2.title').inner_text)
	content = make_ascii(doc.css('.node p').inner_text)

	record = {slug: slug, title: title, content: content, url: file[:url], revision: revision}

	fields = doc.css('.content .field-item').inject(record) do |obj, field|
		
		key, val = make_ascii(field.inner_text).gsub("\n", " ").gsub("\r", " ").strip.squeeze(' ').split(":")
		
		if !key.nil? and !val.nil?
			obj[ key.downcase.gsub(' ','_') ] = val.split(' ').join(' ').strip
		else
			puts "#{slug} -- '#{key}', '#{val}', #{key.nil?}, #{val.nil?}"
		end
		obj
	end
	#p record
	record
end

puts "Uploading final"
file = directory.files.create(key: 'intermediate.json', body: final.to_json, public: true, content_type: 'text/json')
file.save
puts file.public_url
