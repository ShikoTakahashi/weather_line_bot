require "json"
require "open-uri"
require 'date'

class Dark_Sky
  class << self
    API_KEY = ENV["DARK_SKY_KEY"]
    BASE_URL = "https://api.darksky.net/forecast/"
    OPTION_VALUE = "exclude=currently,hourly,minutely,alerts,flags"
    CURRENT_DAY = Date.current
    
    #Dark skyからの気象情報取得
    def get_dark_weather(user)
      response = open(BASE_URL + API_KEY + "/#{user.locate_lat},#{user.locate_lon},#{CURRENT_DAY}T00:00:00Z?units=si&lang=ja&" + OPTION_VALUE)
      weather_data = JSON.parse(response.read, {symbolize_names: true})
      weather_daily = weather_data[:daily][:data][0]
      today_weather = <<~EOS
                        #{weather_daily[:summary]}
                        【最高/最低】
                        #{weather_daily[:temperatureHigh]}/#{weather_daily[:temperatureLow]}℃
                      EOS
      return today_weather
    end
  end
end