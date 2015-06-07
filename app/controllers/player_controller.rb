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

  def new
    @player = Player.new
  end

  def show
    @player= Player.new(params.require(:player).permit(:name))
    @player.name = @player.name.downcase
    @name = @player.summoner_name(@player.name)
    @id = @player.summoner_id(@player.name)

    @player.player_database_check(@player.name)


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
      @champ_name[i] = @player.champ_name(@cid[i])

      match_num -= 1
      i += 1
    end

    #TWITCH
    @twitch_profile = @player.get_twitch_profile(@player.name)
    @twitch_status = @player.get_twitch_status(@twitch_profile)
    @twitch_url = @player.get_twitch_url(@twitch_profile)


    #Twitter
    @twitter_profile = @player.get_twitter_profile(@player.name) rescue true
    unless @twitter_profile
      @twitter_profile = nil
      @tweettime1 = "Twitter profile does not exist for this player."
      @tweettime2 = ""
      @tweettime3 = ""
      @tweettime4 = ""
    end

    client = @player.auth_twitter

    if @twitter_profile
      @tweet = client.user_timeline(@twitter_profile, {count: 4})
      @tweettime1 = @tweet[0].created_at.strftime("%D")
      @tweettime2 = @tweet[1].created_at.strftime("%D")
      @tweettime3 = @tweet[2].created_at.strftime("%D")
      @tweettime4 = @tweet[3].created_at.strftime("%D")
    end

    #YOUTUBE
    client, youtube = @player.get_service
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
    @facebook_profile = @player.get_facebook_profile(@player.name) rescue true
    unless @facebook_profile
      @facebook_profile = nil
      @facebook_post1 = "Facebook profile does not exist for this player."
    end

    if @facebook_profile
      @facebook_post1 = @player.get_facebook_post(@facebook_profile)
    end
  end

end