require "json"
require "open-uri"
require 'date'

class Open_Weather
  class << self
    API_KEY = ENV["OPEN_WEATHER_KEY"]
    BASE_URL = "http://api.openweathermap.org/data/2.5/"
    
    #Openweathermapから気象情報取得
    def get_current_weather(user)
      response = open(BASE_URL + "weather?zip=#{user.address},jp&units=metric&APPID=#{API_KEY}&lang=ja")
      weather_data = JSON.parse(response.read, {symbolize_names: true})
      return "#{weather_data[:weather][0][:description]}\n"
    end
    
    def get_today_weather(user)
      response = open(BASE_URL + "forecast?zip=#{user.address},jp&units=metric&APPID=#{API_KEY}&lang=ja")
      weather_data = JSON.parse(response.read, {symbolize_names: true})
      current_date = Date.current.to_s
      
      today_weather = weather_data[:list].map do |data|
        if(current_date == data[:dt_txt].match(/\d{4}-\d{2}-\d{2}/).to_s) 
          <<~EOS
            ▼#{data[:dt_txt].match(/\d{2}:\d{2}/)}
             #{data[:weather][0][:description]}
          EOS
        end
      end
      return today_weather.compact.join("\n")
    end
    
    def get_weather_city(user)
      response = open(BASE_URL + "forecast?zip=#{user.address},jp&units=metric&APPID=#{API_KEY}")
      weather_data = JSON.parse(response.read, {symbolize_names: true})
      
      return weather_data[:city][:name]
    end
  end
end
