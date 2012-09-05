module PayTheSitter
  class Application
    def initialize(argv)
      @params   = parse_options(argv)
    end

    def run
      raise "dur, you need a start date." if @params[:start_date].nil? 
      raise "you have to say which calendar you are looking at. do you really want to pay the /
            sitter for your shrink and personal trainer appointments?" if @params[:calendar].nil?
      raise "Please provide a pay rate!" if @params[:rate].nil?

      start_date = end_date = nil
      begin
        start_date = Time.parse @params[:start_date]
        end_date = @params[:end_date]  ? Time.parse(@params[:end_date]) :  Time.now
      rescue
        raise "couldn't parse your dates, please fix: format is MM/DD/YYYY"
      end
    
      calendar_api = PayTheSitter::CalendarApi.new

      hours = calendar_api.total_hours_for(@params[:calendar], start_date, end_date)
      #hours += @params[:extra_time].collect 
    end

    def parse_options(argv)
      params = {}
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: pay_the_sitter.rb [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-t",  "--extra_time [1,2,3]", Array, "Extra minutes to add to total time") do |extra_minutes|
          params[:extra_time] = extra_minutes
        end

        opts.on("-m",  "--extra_money [4,3,4]", Array, "Extra money to add to total time") do |extra_money|
          params[:extra_money] = extra_money
        end
        # opts.on("-q",  "--query [QUERY]", "Text to search for in event titles") do |query|
        #   params[:query] = query
        # end
        opts.on("-c",  "--calendar CALENDAR", "calendar name") do |calendar|
          params[:calendar] = calendar
        end
        opts.on("-r",  "--rate RATE", "pay rate") do |rate|
          params[:rate] = rate
        end
        opts.on("-s",  "--start_date START", "start date is required") do |start|
          params[:start_date] = start
        end
        opts.on("-e",  "--end_date [END_DATE]", "end date, defaults to today") do |end_date|
          params[:end_date] = end_date
        end
        opts.on_tail '-h', '--help', 'Print this help' do  
          puts opts  
          exit 0  
        end  
        opts.parse!(argv)
        return params
      end
    end
  end
end


#paythesitter -c babysitting -q sarah -r 15 -m 15,14,6.45 -t 45,15,15 -s 4/20/2012 -e 4/30/2012
# query, extras and end date are all optional