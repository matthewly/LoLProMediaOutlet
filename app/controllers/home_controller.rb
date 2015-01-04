require 'nokogiri'
require 'open-uri'
require 'rubygems'
require 'rest-client'

class HomeController < ApplicationController
  def index
    #@facebook_profile = get_facebook_profile(@player.name)
    #@facebook_post2 = get_facebook_post(@facebook_profile)
    #@facebook_post1 = get_facebook_post(@facebook_profile)
    #@facebook_post3 = get_facebook_post(@facebook_profile)

    #table_headers = page.css('table.infobox2 tr td')

    url = "https://www.facebook.com/clgdoublelift"
    page = Nokogiri::HTML(RestClient.get(url))
    puts page.class   # => Nokogiri::HTML::Document
    table_headers = page.css('body').to_s.split("_5pbx userContent")[1].split("</p>")[0].split("<p>")[1]


    #searched_element = table_headers.search "[text()*='_5pbx userContent']"
    @facebook_post1 = table_headers



  end
end
