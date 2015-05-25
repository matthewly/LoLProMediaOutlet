require 'omniauth'
require 'youtube_it'
require 'nokogiri'
require 'open-uri'
require 'rubygems'
require 'rest-client'
require 'twitter-text'
require 'time'
require 'yt'
require 'yourub'

class PlayerController < ApplicationController
  include Twitter::Autolink

  def new
    @player = Player.new
  end

  def create

    #@user = Player.fin.find_or_create_from_auth_hash(auth_hash)
    #self.current_user = @user
    #redirect_to '/'
    @callback_url = "http://127.0.0.1:3000/oauth/callback"
  end

  def show
    @player= Player.new(params.require(:player).permit(:name))
    @player.name = @player.name.downcase
    @name = summoner_name(@player.name)
    @id = summoner_id(@player.name)

    url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/"+@id.to_s+"?api_key=b1f40660-e8a0-4774-9f65-f107d7ca5559"
    @response = HTTParty.get(URI.encode(url))

    match_num = 9
    i = 0

    @kills = Array.new(5)
    @deaths = Array.new(5)
    @assists = Array.new(5)
    @wins = Array.new(5)
    @ge = Array.new(5)
    @time= Array.new(5)
    @cid = Array.new(5)
    @champ_name= Array.new(5)

    riot_response =  JSON.parse(@response.body)["matches"]

    until match_num < 5 do
      match_history = riot_response[match_num]
      #get_stats(match_history, i)

      @kills[i] = match_history["participants"][0]["stats"]["kills"]
      @deaths[i] = match_history["participants"][0]["stats"]["deaths"]
      @assists[i] = match_history["participants"][0]["stats"]["assists"]
      @wins[i] = match_history["participants"][0]["stats"]["winner"]
      @ge[i] = match_history["participants"][0]["stats"]["goldEarned"]
      @time[i] = match_history["matchDuration"]/60
      @cid[i] = match_history['participants'][0]['championId']
      @champ_name[i] = champ_name(@cid[i])

      match_num -= 1
      i += 1
    end


    #TWITCH
    @twitch_profile = get_twitch_profile(@player.name)
    @twitch_status = get_twitch_status(@twitch_profile)
    @twitch_url = get_twitch_url(@twitch_profile)


    #Twitter
    @twitter_profile = get_twitter_profile(@player.name)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "v6ZGMBIdufzkKgrx19RZQqC5N"
      config.consumer_secret     = "IDI7GMaJn7Bl8N5Zj28cDQ1TxWuRsVFqBtCx1WlrsW7OKLW1Fg"
      config.access_token        = "33024647-tbCYS8cIrdnUH8XLJ65GTHnLuhL2Oz2tEOjmijpE5"
      config.access_token_secret = "lTr3wqMxABmeFJJbHjGs5TFG7jkI8Y9Kmfvvq5RyzpuPP"
    end

    @tweet = client.user_timeline(@twitter_profile, {count: 4})
    @tweettime1 = @tweet[0].created_at.strftime("%D")
    @tweettime2 = @tweet[1].created_at.strftime("%D")
    @tweettime3 = @tweet[2].created_at.strftime("%D")
    @tweettime4 = @tweet[3].created_at.strftime("%D")


    #YOUTUBE
    Yt.configure do |config|
      config.api_key = 'AIzaSyDiO1zdlXLtzqfvo_92lxQuavN3MdU0U4M'
      config.log_level = :debug
    end
    videos = Yt::Collections::Videos.new
    videos.where(order: 'viewCount', q: @player.name, safe_search: 'none')
    @video_id_one = videos.first.id

    #FACEBOOK
    @facebook_profile = get_facebook_profile(@player.name)
    @facebook_post1 = get_facebook_post(@facebook_profile)


  end

  protected
  def auth_hash
    request.env['omniauth.auth']
  end

  private

  def summoner_name(name)
    url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/" + name + "/?api_key=b1f40660-e8a0-4774-9f65-f107d7ca5559"
    @response = HTTParty.get(URI.encode(url))
    no_space_name = name.delete " "
    no_space_lowercase_name = no_space_name.downcase
    @json =  JSON.parse(@response.body)[no_space_lowercase_name]["name"]
    return @json
  end

  def summoner_id(name)
    url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/" + name + "/?api_key=b1f40660-e8a0-4774-9f65-f107d7ca5559"
    @response = HTTParty.get(URI.encode(url))
    no_space_name = name.delete " "
    no_space_lowercase_name = no_space_name.downcase
    @json =  JSON.parse(@response.body)[no_space_lowercase_name]["id"]
    return @json
  end

  def get_stats(match_history, i)
    @kills = Array.new(5)

    @kills = match_history["participants"][0]["stats"]["kills"]
    @deaths = match_history["participants"][0]["stats"]["deaths"]
    @assists = match_history["participants"][0]["stats"]["assists"]
    @win = match_history["participants"][0]["stats"]["winner"]
    @ge = match_history["participants"][0]["stats"]["goldEarned"]
    @time = match_history["matchDuration"]/60
    cid = match_history['participants'][0]['championId']
    @champ_name = champ_name(cid)
  end

  def get_match_history(id,num)
    url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/"+id.to_s+"?api_key=b1f40660-e8a0-4774-9f65-f107d7ca5559"
    @response = HTTParty.get(URI.encode(url))
    @json =  JSON.parse(@response.body)["matches"][num]
    return @json
  end

  def champ_name(champ_id)
    url = "https://na.api.pvp.net//api/lol/static-data/na/v1.2/champion/"+champ_id.to_s+"?api_key=b1f40660-e8a0-4774-9f65-f107d7ca5559"
    @response = HTTParty.get(URI.encode(url))
    @json =  JSON.parse(@response.body)["name"]
    return @json
  end

  #TWITCH
  def get_twitch_profile(name)
    t1 = Player.find_by name:name
    @twitch_profile = t1.twitch_prof
    return @twitch_profile
  end

  def get_twitch_status(profile)
    url = "https://api.twitch.tv/kraken/channels/"+profile
    @response = HTTParty.get(URI.encode(url))
    @json =  JSON.parse(@response.body)["status"]
    return @json
  end

  def get_twitch_url(profile)
    url = "https://api.twitch.tv/kraken/channels/"+profile
    @response = HTTParty.get(URI.encode(url))
    @json =  JSON.parse(@response.body)["url"]
    return @json
  end

  def get_facebook_profile(name)
    f1 = Player.find_by name:name
    @facebook_profile = f1.facebook_prof
    return @facebook_profile
  end

  def get_twitter_profile(name)
    t1 = Player.find_by name:name
    @twitter_profile = t1.twitter_prof
    return @twitter_profile
  end

  def get_facebook_post(profile)
    url = "https://www.facebook.com/"+profile
    page = Nokogiri::HTML(RestClient.get(url))
    puts page.class   # => Nokogiri::HTML::Document
    table_headers = page.css('body').to_s.split("_5pbx userContent")[1].split("</p>")[0].split("<p>")[1]

    @facebook_post1 = table_headers
    return @facebook_post1
  end

  def twitter_text(text)
    text = auto_link(text)
    text ? text.html_safe : ''
  end

  def facebook_text(text)
    text = auto_link(text)
    text ? text.html_safe : ''
  end

end