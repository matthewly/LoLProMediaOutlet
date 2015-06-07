class Player < ActiveRecord::Base
  DEVELOPER_KEY = 'AIzaSyBFwUV1Dnv9pIBI0TckppPDBudKovcuENU'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'

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

  def auth_twitter
    return Twitter::REST::Client.new do |config|
      config.consumer_key        = "v6ZGMBIdufzkKgrx19RZQqC5N"
      config.consumer_secret     = "IDI7GMaJn7Bl8N5Zj28cDQ1TxWuRsVFqBtCx1WlrsW7OKLW1Fg"
      config.access_token        = "33024647-tbCYS8cIrdnUH8XLJ65GTHnLuhL2Oz2tEOjmijpE5"
      config.access_token_secret = "lTr3wqMxABmeFJJbHjGs5TFG7jkI8Y9Kmfvvq5RyzpuPP"
    end
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
