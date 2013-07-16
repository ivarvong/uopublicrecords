require 'open-uri'
require 'sucker_punch'
require 'fog'
require 'dotenv'
require 'digest/md5'

Dotenv.load

class RefreshJob
	include SuckerPunch::Job	

	def initialize		
		storage = Fog::Storage.new(:provider => 'AWS', :aws_access_key_id => ENV['ACCESS_KEY'], :aws_secret_access_key => ENV['SECRET_KEY'])		
		@s3 = storage.directories.create(key: ENV['BUCKET'])
	end

	def perform
		time_start = Time.now

		links = get_index_links()
		links.each do |link|
			raw = open("http://publicrecords.uoregon.edu#{link}") 
			doc = Nokogiri::HTML(raw)
			slug = link.gsub("/content/", "")
			text = doc.css('#content').text
			md5 = Digest::MD5.hexdigest(text)
			key = "original/#{slug}/#{md5}"
			if file_exists?(key)
				puts "...already have #{key}"
			else 
				puts save_file(key, raw)
			end
		end

		puts "RefreshJob: perform took #{Time.now - time_start} seconds" # this could be, like, logged, you know?
	end

	def get_index_links
		all_links = []		
		(0..3).to_a.each do |page| # goes back to 42 when i first ran it 
			doc = Nokogiri::HTML(open("http://publicrecords.uoregon.edu/requests?page=#{page}"))	
			doc.css('td a').each do |link| 
				all_links << link.attr('href')
			end
			sleep(rand())
			puts "finished page #{page}, have #{all_links.count} links so far"
		end			
		return all_links
	end

	def save_file(key, body)
		file = @s3.files.create(key: key, body: body, public: true, options: {'Content-Type' => 'text/html'})
		file.save
		return file.public_url
	end

	def file_exists?(key)
		# could one-liner this. but i think this is a bit clearer. (?)
		if @s3.files.head(key).nil?
			return false
		else
			return true
		end
	end

	#def test()
	#	test_key = "blahblahblah"
	#	puts "expect false:", file_exists?(test_key)
	#	puts "expect url:", save_file(test_key, "the test content TWO")
	#	puts "expect true:", file_exists?(test_key)
	#end
end