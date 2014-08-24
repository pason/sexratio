require 'sinatra'
require 'koala'
require "net/http"
require "uri"
require "json"
require 'sinatra/base'
require 'sinatra/assetpack'
require 'chartkick'


#config
APP_ID = '631312703619289'
APP_SECRET = '7f2424ae09f0fbbf008eae86307382f2'
CALLBACK_URL = '/'

#Prepare graph
oauth = Koala::Facebook::OAuth.new(APP_ID, APP_SECRET, CALLBACK_URL)
oauth_access_token = oauth.get_app_access_token
graph = Koala::Facebook::API.new(oauth_access_token)



#Assets configuration
set :root, File.dirname(__FILE__) 

register Sinatra::AssetPack

assets {
serve '/js',     from: 'app/js'        # Default
serve '/css',    from: 'app/css'       # Default
serve '/images', from: 'app/images'    # Default


js :app, [
  '/js/*.js'
]

css :application, [
  '/css/styles.css'
]

js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
css_compression :simple   # :simple | :sass | :yui | :sqwish
}





#actions
get '/' do
	erb :index
end

post '/' do

	gender = {attending: {}, maybe: {}, ratio: {}}
	match = /events\/(\d+)/.match(params[:event][:url])

	if !match.nil?

		event_id = match[1] 

		event_info = event_attending = graph.get_object(event_id)
		event_attending = graph.get_object("#{event_id}/attending/?fields=first_name")
		event_maybe = graph.get_object("#{event_id}/maybe/?fields=first_name")
		
		
		gender[:attending] = genderize_names(event_attending)
		gender[:maybe] = genderize_names(event_maybe)

		attending_total = gender[:attending][:male] + gender[:attending][:female] + gender[:attending][:unrecognized]
		gender[:ratio][:male] = ((gender[:attending][:male].to_f/attending_total.to_f) * 100).round(2)
		gender[:ratio][:female] = ((gender[:attending][:female].to_f/attending_total.to_f)*100).round(2)
		gender[:ratio][:unrecognized] = ((gender[:attending][:unrecognized].to_f/attending_total.to_f)*100).round(2)
		
			
	end

	erb :index, locals: {gender: gender, event: event_info} 

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