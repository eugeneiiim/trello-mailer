require 'rubygems'
require 'json'
require "net/https"

url_str = "https://api.trello.com/1/boards/#{ENV['TRELLO_BOARD_ID']}/cards?key=#{ENV['TRELLO_KEY']}&token=#{ENV['TRELLO_TOKEN']}"
puts url_str

uri = URI.parse(url_str)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

request = Net::HTTP::Get.new(uri.request_uri)

response = http.request(request)
cards = JSON.parse(response.body)
puts cards.length

Pony.mail(:to => ENV['EMAIL_ADDR'],
          :from => ENV['SENDGRID_USERNAME'],
          :subject => subject,
          :body => body,
          :via_options => {
            :address => 'smtp.sendgrid.net',
            :port => '587',
            :domain => 'heroku.com',
            :user_name => ENV['SENDGRID_USERNAME'],
            :password => ENV['SENDGRID_PASSWORD'],
            :authentication => :plain,
            :enable_starttls_auto => true
          })
