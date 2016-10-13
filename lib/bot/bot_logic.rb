

class BotLogic < BaseBotLogic

  BUNDESLAENDER = %W(Wien Kärnten Burgenland Tirol Salzburg Steiermark Vorarlberg Niederösterreich Oberösterreich)

	def self.setup
		set_welcome_message "Hi! Ich informiere dich über das Sauwetter :pig: :sunny: :umbrella:"
		set_get_started_button "bot_start_payload"
		set_bot_menu
	end

	def self.cron
		broadcast_all ":princess:"
	end

	def self.bot_logic
		ENV["DOMAIN_NAME"] = "https://9ec6211c.ngrok.io"


    # reply_message, reply_image, reply_html

    if @request_type == "CALLBACK"
      case @fb_params.payload
      when "RESET_BOT"
        @current_user.delete
        reply_message "Removed all your data from our servers."
        reply_message "Hello"
        return
      end
    end

    state_action 0, :location
    state_action 1, :set_time
    state_action 2, :got_time
    state_action 3, :weather
	end

  def self.set_time
		location = get_message

		@current_user.profile = {location: location}
		@current_user.save!

		reply_quick_reply "Oink! At what time would you like me to let you know what the weather will pig like?", %W(7AM 8AM 9AM 10AM)
		state_go
	end

  def self.got_time
    begin
      due_date = Date.parse get_message
      @current_user.profile.merge time: due_date.to_s
      @current_user.save!
    rescue ArgumentError
    end

    reply_message "Great! I'll send you your weather update at #{get_message}"
    self.send_weather
    state_go
  end

  def self.weather
    self.send_weather
  end

	def self.location
		reply_quick_reply "Please pick your bundesland", BUNDESLAENDER
		state_go
	end

	def self.subscribe
		due_date = Date.parse get_message

		@current_user.profile = {due_date: due_date.to_s}
		@current_user.save!

		reply_quick_reply "Okay #{due_date.to_s}. Did I get it right?"
		state_go
	rescue ArgumentError
		reply_message "{Sorry I do not undestand this format|Can you try again? Format is DD/MM/YYYY}"
	end

	def self.confirm
		if get_message == "Yes"
			subscribe_user("pregnant")
			state_go
			reply_message "Awwww sweet! You are all set now. I'll start to track your pregnancy for you. Can't wait :bride_with_veil::heart::baby_bottle:"
		else
			reply_message "Ohh Sorry, please use this format: DD/MM/YYYY"
			@current_user.profile = {}
			@current_user.save!
			state_reset
		end
	end

	def self.onboarded
		output_current_week
	end

	### helper functions

	def self.calculate_current_week
		user_date = Date.parse @current_user.profile[:due_date]
		server_date = Date.parse Time.now.to_s

		40 - ((user_date - server_date).to_i / 7)
	end

	def self.output_current_week
		current_week = calculate_current_week
		reply_message "you are in week number #{current_week}"
	end

  def self.send_weather
    response = HTTParty.get("http://wetter.orf.at/api/json/1.0/package")

    hash = JSON.parse(response.body)
    if @current_user.profile
      location = @current_user.profile[:location].downcase if BUNDESLAENDER.include?(@current_user.profile[:location].capitalize)
    end
    location ||= 'wien'
    location.gsub! /ö/, 'oe'
    puts location
    temperature = hash[location]['current']['temperature']
    chance_of_rain = hash[location]['current']['precipitation']

    reply_message ":pig: It's currently #{temperature} degrees with a #{chance_of_rain}% chance of rain :pig:"

    piggy_pics = {}
    CSV.foreach('lib/tasks/weatherpigs.csv', headers: true) do |row|
      piggy_pics[row['WEATHER']] ||= []
      piggy_pics[row['WEATHER']] << row['URL']
    end


    if temperature.to_f < 10
      reply_message "It's a little cold out. Don't forget your scarf on the way out!"
      images = piggy_pics['cold']
    else
      reply_message "It's sweltering! Got time for a swim today?"
      images = piggy_pics['sunny']
    end

    if chance_of_rain > 20
      reply_message "Look out! It's very likely going to rain! Be sure to wear some boots and an umbrella."
      images = piggy_pics['rainy']
    end


    reply_image images.sample




  end

end
