desc "Update some stuff"
task :update  do
	base_url = ENV['BASE_URL'] || 'http://localhost:9292/'
	endpoint = ENV['ENDPOINT'] || 'test'
	puts `curl -s "#{base_url}#{endpoint}"`
end