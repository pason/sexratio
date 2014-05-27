require 'sinatra'
require 'koala'
require "net/http"
require "uri"
require "json"

oauth_access_token = "CAACEdEose0cBAAeZBIkl3xGWakvdgapSZAw9L1WRonUlHBsh5T6IMdOjSHb7VAfNSOYIzzzFwJDVBRngPkCXBjZCV8glZBQDBL4B87QkwsWDPA3JMwTS1t1JE3COChtmGZBltNltuojrdvaqjEx9YWaLR8rZBXSfyS39VKbnqTHLwBSCVRYrEfRGsGs7URR44OKNUOMJjRNgZDZD"


graph = Koala::Facebook::API.new(oauth_access_token)




get '/' do
	erb :index
end

post '/' do

	gender = {attending: {}, maybe: {}}
	match = /events\/(\d+)/.match(params[:event][:url])

	if !match.nil?

		event_id = match[1] 

		event_attending = graph.get_object("#{event_id}/attending/?fields=first_name")
		event_maybe = graph.get_object("#{event_id}/maybe/?fields=first_name")
		
		
		gender[:attending] = genderize_names(event_attending)
		gender[:maybe] = genderize_names(event_maybe)
		
			
	end

	erb :index, locals: {gender: gender} 

end


def genderize_names(people)
	gender = {male: 0, female: 0, unrecognized: 0, unbucket: []}

	params = ''
	people.each_with_index do |user, id| 
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
			if user["gender"].nil?
				gender[:unrecognized] += 1
				gender[:unbucket] << user["name"]
			end 
		end
	else
		puts "ERROR!!!"
	end

	return gender
end