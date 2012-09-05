require 'google/api_client'
require './commandline_oauth'
require 'json'
require 'american_date'
# Create a new API client & load the Google+ API 
module PayTheSitter
 class CalendarApi
	def initialize
		@client = Google::APIClient.new
		@calendar = @client.discovered_api('calendar', 'v3')
		auth_util = PayTheSitter::CommandLineOAuthHelper.new('https://www.googleapis.com/auth/calendar.readonly')
		@client.authorization = auth_util.authorize()
	end

	def find_cal_id_from_description(description)
		results = @client.execute(:api_method => @calendar.calendar_list.list)
		body = results.response.body
		body = JSON.parse(body)
		ids_and_descs = body["items"].inject({}) { |hsh, cal| hsh[cal["summary"]] = cal["id"] ; hsh}
		return ids_and_descs[description]
	end


	def scoped_to_single_cal_get_all_events_between(summary, min_date, max_date)
		cal_id = find_cal_id_from_description(summary)
		#2011-06-03T10:00:00.000-07:00
		parameters = {'calendarId' => "#{cal_id || 'primary'}", 
                           'timeMin' => "#{to_google_string_from_datetime(min_date)}", 
                           'timeMax' =>"#{to_google_string_from_datetime(max_date)}"
                      }
		results = @client.execute(:api_method => @calendar.events.list, :parameters => parameters)
		return JSON.parse(results.response.body)["items"]
	end

	def total_hours_for(cal, min_date, max_date)
		items = scoped_to_single_cal_get_all_events_between(cal, min_date, max_date)
		# don't stay out past midnight, yo
		return 0 unless items && items.any?
		total = items.inject(0){| sum, item| sum+= ( to_datetime_from_google_string(item['end']['dateTime'])-
											 to_datetime_from_google_string(item['start']['dateTime']))}
		total/3600  # gives me hours
	end

	def to_datetime_from_google_string(str)
	#2011-06-03T10:00:00.000-07:00
		return 0 unless str
		str,junk = str.split(".")
		time = DateTime.strptime(str, "%Y-%m-%dT%H:%M:%S").to_time
	end

	#2011-06-03T10:00:00.000-07:00
	def to_google_string_from_datetime(datetime)
		datetime.strftime("%Y-%m-%dT%H:%M:%S.000%z")
	end
  end
end

