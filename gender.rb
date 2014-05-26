require 'sinatra'
require 'koala'
require "net/http"
require "uri"
require "json"

oauth_access_token = "CAACEdEose0cBANAlZCCYV5eZCszQlkROYH31STwbyX8zZAL0lvpExyOZApGYdMT3PYStr6PtE0WuJ2GXLMJ6Jif2eFIZADvq9xISzKU93YxMQ6kEpw25I3e4lrKK20M0P1d1lGNkZA1JCTc5fRIf8ZCjKnZBpDMPPG8bAIKM8ynVtDhAOQ58C3yuRPc22WZAB9PwrZBBBuVp2ilgZDZD"


graph = Koala::Facebook::API.new(oauth_access_token)
gender = {male: 0, female: 0, unrecognized: 0}


get '/' do

	event_id = 1379868408963536 

	attending = graph.get_object("#{event_id}/attending/?fields=first_name")
	
	params = ''
	attending.each_with_index do |user, id| 
		params += "name[#{id}]=#{user['first_name']}&"
	end
	params = params.chomp('&')


	url = "http://api.genderize.io?"+params
	url = URI.encode(url.strip)

	uri = URI.parse(url)
 
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Get.new(uri.request_uri)
	 
	response = http.request(request)
	result = {}
	if response.code == "200"
		result = JSON.parse(response.body)
		result.each do |user|
			gender[:male] += 1 if user["gender"] == "male"
			gender[:female] += 1 if user["gender"] == "female"
			gender[:unrecognized] += 1 if user["gender"].nil?
		end
	else
		puts "ERROR!!!"
	end

	raise gender.inspect

end