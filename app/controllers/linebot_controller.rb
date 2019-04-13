class LinebotController < ApplicationController
  require 'date'
  require 'line/bot'
  require './app/api/open_weather'
  require './app/api/dark_sky'
  
  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]
  DATE = Date.current

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end
    events = client.parse_events_from(body)
    user_name = events[0]['source']['userId']
    
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = text_reply_message(event, user_name)
        when Line::Bot::Event::MessageType::Location
          message = location_relpy_message(event, user_name)
        end
      end
      client.reply_message(event['replyToken'], message)
    end
    head :ok
  end
  
  def text_reply_message(event, user_name)
    if event_user = User.find_by(name: user_name)
      case event['message']['text']
      when "現在の天気は？"
        weather_hour = Open_Weather.get_current_weather(event_user)
        city_name = Open_Weather.get_weather_city(event_user)
        message = {
                   type: 'text',
                   text: "【#{DATE.month}月#{DATE.day}日】のお天気(City: #{city_name})\n#{ weather_hour}"
        }
      when "今日の天気は？"
        message = get_locate_weather(event_user)
      end
    else
      message = {
        type: 'text',
        text: "位置情報が登録されていません。"
      }
    end
  end
  
  def location_relpy_message(event, user_name)
    lat = event['message']['latitude'].to_s
    lon = event['message']['longitude'].to_s
    address = event['message']['address'].match(/\d{3}-\d{4}/).to_s
    if event_user = User.find_by(name: user_name)
      locate_update(event_user, lat, lon, address)
      message = {
      type: 'text',
      text: "位置情報を更新しました"
    }
    else
      locate_create(user_name, lat, lon, address)
      message = {
        type: 'text',
        text: "位置情報を登録完了しました"
      }
    end
  end
  
  def get_locate_weather(user)
    weather_hours = Open_Weather.get_today_weather(user)
    city_name = Open_Weather.get_weather_city(user)
    weather_daily = Dark_Sky.get_dark_weather(user)
    message = {
               type: 'text',
               text: "【#{DATE.month}月#{DATE.day}日】のお天気(City: #{city_name})\n#{weather_daily}\n時系列予報はこちら！\n" + weather_hours
    }
  end
  
  def push_message
    all_users = User.all
    all_users.each do |user|
      client.push_message(user.user_name, get_locate_weather(user))
    end
  end
  
  private
  
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
  
  def locate_create(u_name, lat, lon, address)
    user = User.new
    user.name = u_name
    user.locate_lat = lat
    user.locate_lon = lon
    user.address = address
    user.save
  end
  
  def locate_update(event_user, lat, lon, address)
    event_user.locate_lat = lat
    event_user.locate_lon = lon
    event_user.address = address
    event_user.save
  end
end