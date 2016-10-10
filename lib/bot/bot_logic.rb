
require 'csv'

class BotLogic < BaseBotLogic

  BUNDESLAENDER = %W(Wien Niederösterreich Oberösterreich Kärnten Burgenland Vorarlberg Tirol Salzburg Steiermark)

	def self.setup
		set_welcome_message "Welcome!"
		set_get_started_button "bot_start_payload"
		set_bot_menu
	end

	def self.cron
		broadcast_all ":princess:"
	end

	def self.bot_logic
		ENV["DOMAIN_NAME"] = "https://82be97d0.ngrok.io"


		if @request_type == "CALLBACK" and @fb_params.payload == "RESET_BOT"
			@current_user.delete
			reply_message "Removed all your data from our servers."
			return
		end

		state_action 0, :languages
		state_action 1, :bundesland
		state_action 2, :main_menu
		state_action 3, :main_menu_chosen
		state_action 4, :social
		state_action 5, :legal
		state_action 6, :german
		state_action 7, :contacts
		state_action 8, :housing
    state_action 9, :more_numbers
	end

  def self.languages
    reply_message "What language do you speak?"
    reply_quick_reply "ما اللغة التي تتحدثها؟", %W(English العربية)
    state_go
  end

  def self.bundesland
    if get_message == "العربية"
      reply_message "آسف، وهذا غير متوفر حتى الآن."
    end
    reply_message "Hello I am your new Fränz!"
    reply_quick_reply "I can't wait to get to know you and be your helpful friend! Before we start, could you please tell me what state (Bundesland) you live in?", BUNDESLAENDER
		state_go
  end

	def self.main_menu
    bundesland = get_message
    if BUNDESLAENDER.include? bundesland
      @current_user.profile = {bundesland: bundesland}
      @current_user.save!
    end

		reply_quick_reply "What do you need help with?", ["Social", "Legal", "German Translation", "Contacts", "Housing", "Help I just got here"]
		state_go
	end

  def self.more_numbers
    if get_message.downcase == 'show more'
      reply_message "Here are some viennese emergency contact numbers:"
      CSV.foreach("numbers_wien_more.csv") { |row| reply_message "#{row[0]} — #{row[1]} (#{row[2]})"}
      reply_quick_reply "Anything else you need help with?", ["Social", "Legal", "German Translation", "Contacts", "Housing", "Help I just got here"]
    else
      reply_quick_reply "What do you need help with?", ["Social", "Legal", "German Translation", "Contacts", "Housing", "Help I just got here"]
    end
    state_go 3
  end

  def self.main_menu_chosen
    case get_message.downcase
    when "social"
      self.not_available
    when "legal"
      self.not_available
    when "german translation"
      self.not_available
    when "contacts"
      reply_message "Here are the Austrian emergency contact numbers:"
      CSV.foreach("numbers_wien.csv") { |row| reply_message "#{row[0]} — #{row[1]} (#{row[2]})"}
      reply_quick_reply "Did you find what you needed?", ["Show more", "Main Menu"]
      state_go 9
    when "housing"
      self.not_available
    when "help i just got here"
      reply_message "Welcome to Austria!"
      reply_message "First things first, you need to claim asylum. To do so, go to the nearest police station."
      if self.current_user_bundesland == 'wien'
        reply_message "If you've just arrived at Westbahnhof, you can find the local police station here:"
        reply_image "http://i.imgur.com/anJZqke.png"
      elsif self.current_user_bundesland == 'kärnten'
        reply_message "If you've just arrived in the Klagenfurt Hauptbahnhof, you can find the local police station here:"
        reply_image "http://i.imgur.com/1D0U45D.png"
      end
      reply_message "The police should inform you how to proceed from there."
      reply_message "If you need further information, check out the following link (English): http://www.w2eu.info/austria.en/articles/austria-asylum.en.html"
      reply_quick_reply "Anything else you need help with?", ["Social", "Legal", "German Translation", "Contacts", "Housing", "Help I just got here"]
      state_go 3
    else
      reply_message "Sorry I didn't understand that. Please make sure to only choose one of the buttons! :cat:"
      reply_quick_reply "What do you need help with?", ["Social", "Legal", "German Translation", "Contacts", "Housing", "Help I just got here"]
      state_go 3
    end
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

  def self.current_user_bundesland
    if @current_user.profile
      @current_user.profile[:bundesland].downcase
    end
  end

  def self.not_available
    reply_quick_reply "Sorry, this isn't available yet. We need your help, so if you can lend us some assistance, we'd highly appreciate it. Until then, please pick another option", ["Social", "Legal", "German Translation", "Contacts", "Housing", "Help I just got here"]
    state_go 3
  end

end
