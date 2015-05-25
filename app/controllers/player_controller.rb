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

    #match_history =  JSON.parse(@response.body)["matches"][9]
    #get_stats(match_history)

    #match_history = get_match_history(@id,9)
    #@kills = match_history["participants"][0]["stats"]["kills"]
    #@deaths = match_history["participants"][0]["stats"]["deaths"]
    #@assists = match_history["participants"][0]["stats"]["assists"]
    #@win = match_history["participants"][0]["stats"]["winner"]
    #@ge = match_history["participants"][0]["stats"]["goldEarned"]
    #@time = match_history["matchDuration"]/60
    #cid = match_history['participants'][0]['championId']
    #@champ_name = champ_name(cid)

    #match_history = get_match_history(@id,8)
    #@kills1 = match_history["participants"][0]["stats"]["kills"]
    #@deaths1 = match_history["participants"][0]["stats"]["deaths"]
    #@assists1 = match_history["participants"][0]["stats"]["assists"]
    #@win1 = match_history["participants"][0]["stats"]["winner"]
    #@ge1 = match_history["participants"][0]["stats"]["goldEarned"]
    #@time1 = match_history["matchDuration"]/60
    #@cid = match_history['participants'][0]['championId']
    #@champ_name1 = champ_name(@cid)
#
    #match_history = get_match_history(@id,7)
    #@kills2 = match_history["participants"][0]["stats"]["kills"]
    #@deaths2 = match_history["participants"][0]["stats"]["deaths"]
    #@assists2 = match_history["participants"][0]["stats"]["assists"]
    #@win2 = match_history["participants"][0]["stats"]["winner"]
    #@ge2 = match_history["participants"][0]["stats"]["goldEarned"]
    #@time2 = match_history["matchDuration"]/60
    #@cid = match_history['participants'][0]['championId']
    #@champ_name2 = champ_name(@cid)
#
    #match_history = get_match_history(@id,6)
    #@kills3 = match_history["participants"][0]["stats"]["kills"]
    #@deaths3 = match_history["participants"][0]["stats"]["deaths"]
    #@assists3 = match_history["participants"][0]["stats"]["assists"]
    #@win3 = match_history["participants"][0]["stats"]["winner"]
    #@ge3 = match_history["participants"][0]["stats"]["goldEarned"]
    #@time3 = match_history["matchDuration"]/60
    #@cid = match_history['participants'][0]['championId']
    #@champ_name3 = champ_name(@cid)
#
    #match_history = get_match_history(@id,5)
    #@kills4 = match_history["participants"][0]["stats"]["kills"]
    #@deaths4 = match_history["participants"][0]["stats"]["deaths"]
    #@assists4 = match_history["participants"][0]["stats"]["assists"]
    #@win4 = match_history["participants"][0]["stats"]["winner"]
    #@ge4 = match_history["participants"][0]["stats"]["goldEarned"]
    #@time4 = match_history["matchDuration"]/60
    #@cid = match_history['participants'][0]['championId']
    #@champ_name4 = champ_name(@cid)

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
    #url = "http://lol.gamepedia.com/"+name
    #page = Nokogiri::HTML(RestClient.get(url))
    #puts page.class   # => Nokogiri::HTML::Document
    #table_headers = page.css('table.infobox2 tr')
    #searched_element = table_headers.search "[text()*='Twitch.']"
    #twitch_link = searched_element[0]['href']
    #if twitch_link.include? "https"
    #  if twitch_link.include? "www"
    #    twitch_profile_substring = twitch_link.sub("https://www.twitch.tv/", "")
    #  else
    #    twitch_profile_substring = twitch_link.sub("https://twitch.tv/", "")
    #  end
    #else
    #  if twitch_link.include? "www"
    #    twitch_profile_substring = twitch_link.sub("http://www.twitch.tv/", "")
    #  else
    #    twitch_profile_substring = twitch_link.sub("http://twitch.tv/", "")
    #  end
    #end
    #@twitch_profile = twitch_profile_substring
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
    #url = "http://lol.gamepedia.com/"+name
    #page = Nokogiri::HTML(RestClient.get(url))
    #puts page.class   # => Nokogiri::HTML::Document
    #table_headers = page.css('table.infobox2 tr')
    #searched_element = table_headers.search "[text()*='Facebook Fan']"
    #facebook_link = searched_element[0]['href']
    #if facebook_link.include? "https"
    #  if facebook_link.include? "www"
    #    facebook_profile_substring = facebook_link.sub("https://www.facebook.com/", "")
    #  else
    #    facebook_profile_substring = facebook_link.sub("https://facebook.com/", "")
    #  end
    #else
    #  if facebook_link.include? "www"
    #    facebook_profile_substring = facebook_link.sub("http://www.facebook.com/", "")
    #  else
    #    facebook_profile_substring = facebook_link.sub("http://facebook.com/", "")
    #  end
    #end
    #@facebook_profile = facebook_profile_substring
    f1 = Player.find_by name:name
    @facebook_profile = f1.facebook_prof
    return @facebook_profile
  end

  def get_twitter_profile(name)
    #url = "http://lol.gamepedia.com/"+name
    #page = Nokogiri::HTML(RestClient.get(url))
    #puts page.class   # => Nokogiri::HTML::Document
    #table_headers = page.css('table.infobox2 tr td')
    #searched_element = table_headers.search "[text()*='@']"
    #twitter_link = searched_element[0]['href']
    #if twitter_link.include? "https"
    #  if twitter_link.include? "www"
    #    twitter_profile_substring = twitter_link.sub("https://www.twitter.com/", "")
    #  else
    #    twitter_profile_substring = twitter_link.sub("https://twitter.com/", "")
    #  end
    #else
    #  if twitter_link.include? "www"
    #    twitter_profile_substring = twitter_link.sub("http://www.twitter.com/", "")
    #  else
    #    twitter_profile_substring = twitter_link.sub("http://twitter.com/", "")
    #  end
    #end
    #@twitter_profile = twitter_profile_substring
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