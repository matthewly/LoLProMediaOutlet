require 'omniauth'
require 'youtube_it'
require 'nokogiri'
require 'open-uri'
require 'rubygems'
require 'rest-client'
require 'twitter-text'
require 'time'
require 'google/api_client'

class PlayerController < ApplicationController
  include Twitter::Autolink

  DEVELOPER_KEY = 'AIzaSyBFwUV1Dnv9pIBI0TckppPDBudKovcuENU'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'

  def new
    @player = Player.new
  end

  def show
    @player= Player.new(params.require(:player).permit(:name))
    @player.name = @player.name.downcase
    @name = summoner_name(@player.name)
    @id = summoner_id(@player.name)

    unless Player.exists?(:name => @player.name)
      #redirect_to player_new_path(:controller => 'player', :action => 'new')
      redirect_to root_path(:notice => 'Player does not exist in NA LCS database. Please try again.')
      return
    end

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

    flag = 0

    riot_response =  JSON.parse(@response.body)["matches"] rescue true
    unless riot_response
      @kills[i] = ""
      @deaths[i] = ""
      @assists[i] = ""
      @wins[i] = ""
      @ge[i] = ""
      @time[i] = ""
      @cid[i] = ""
      @champ_name[i] =
      @kills[0] = riot_response
      flag = nil
    end

    until match_num < 5 do
      match_history = riot_response[match_num] rescue true

      @kills[i] = match_history["participants"][0]["stats"]["kills"] rescue 0
      @deaths[i] = match_history["participants"][0]["stats"]["deaths"] rescue 0
      @assists[i] = match_history["participants"][0]["stats"]["assists"] rescue 0
      @wins[i] = match_history["participants"][0]["stats"]["winner"] rescue 0
      @ge[i] = match_history["participants"][0]["stats"]["goldEarned"] rescue 0
      @time[i] = match_history["matchDuration"]/60 rescue 0
      @cid[i] = match_history['participants'][0]['championId'] rescue 0
      @champ_name[i] = champ_name(@cid[i])

      match_num -= 1
      i += 1
    end

    #TWITCH
    @twitch_profile = get_twitch_profile(@player.name)
    @twitch_status = get_twitch_status(@twitch_profile)
    @twitch_url = get_twitch_url(@twitch_profile)


    #Twitter
    @twitter_profile = get_twitter_profile(@player.name) rescue true
    unless @twitter_profile
      @twitter_profile = nil
      @tweettime1 = "Twitter profile does not exist for this player."
      @tweettime2 = ""
      @tweettime3 = ""
      @tweettime4 = ""
    end

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "v6ZGMBIdufzkKgrx19RZQqC5N"
      config.consumer_secret     = "IDI7GMaJn7Bl8N5Zj28cDQ1TxWuRsVFqBtCx1WlrsW7OKLW1Fg"
      config.access_token        = "33024647-tbCYS8cIrdnUH8XLJ65GTHnLuhL2Oz2tEOjmijpE5"
      config.access_token_secret = "lTr3wqMxABmeFJJbHjGs5TFG7jkI8Y9Kmfvvq5RyzpuPP"
    end

    if @twitter_profile
      @tweet = client.user_timeline(@twitter_profile, {count: 4})
      @tweettime1 = @tweet[0].created_at.strftime("%D")
      @tweettime2 = @tweet[1].created_at.strftime("%D")
      @tweettime3 = @tweet[2].created_at.strftime("%D")
      @tweettime4 = @tweet[3].created_at.strftime("%D")
    end


    #YOUTUBE
    client, youtube = get_service
    search_response = client.execute!(
        :api_method => youtube.search.list,
        :parameters => {
            :part => 'snippet',
            :q => 'league of legends ' + @player.name,
            :maxResults => 1
        }
    )

    @video_id = search_response.data.items[0].id.videoId

    #FACEBOOK
    @facebook_profile = get_facebook_profile(@player.name) rescue true
    unless @facebook_profile
      @facebook_profile = nil
      @facebook_post1 = "Facebook profile does not exist for this player."
    end

    if @facebook_profile
      @facebook_post1 = get_facebook_post(@facebook_profile)
    end
  end

  private

  def get_service
    client = Google::APIClient.new(
        :key => DEVELOPER_KEY,
        :authorization => nil,
        :application_name => $PROGRAM_NAME,
        :application_version => '1.0.0'
    )
    youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)

    return client, youtube
  end

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
    @json =  JSON.parse(@response.body)["name"] rescue "No champ played recently"
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
    @facebook_post1 = table_headers.split('<')[0]
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