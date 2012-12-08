require 'rubygems'
require 'json'
require 'redis'
require "net/https"
require 'pony'

ruri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => ruri.host, :port => ruri.port, :password => ruri.password)

ACTIONS_KEY = "#{ENV['TRELLO_BOARD_ID']}:actions"

def get_json(url_str)
  uri = URI.parse(url_str)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  JSON.parse(response.body)
end

def get_actions
  get_json("https://api.trello.com/1/boards/#{ENV['TRELLO_BOARD_ID']}/actions?key=#{ENV['TRELLO_KEY']}&token=#{ENV['TRELLO_TOKEN']}&filter=createCard")
end

def get_card_url(id)
  get_json("https://api.trello.com/1/cards/#{id}?key=#{ENV['TRELLO_KEY']}&token=#{ENV['TRELLO_TOKEN']}&fields=url")['url']
end

def get_prev_actions
  prev_json = REDIS.get(ACTIONS_KEY)
  if prev_json
    JSON.parse(prev_json)
  else
    []
  end
end

def set_latest_actions(actions)
  REDIS.set(ACTIONS_KEY, actions.to_json)
end

def send_email(subject, body)
  puts "Sending #{subject} to #{ENV['EMAIL_ADDR']}..."
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
  puts "Sent."
end

prev_actions = get_prev_actions()
cur_actions = get_actions()
new_actions = cur_actions - prev_actions

new_actions[0..3].each do |action|
  card_id = action['data']['card']['id']
  card_url = get_card_url(action['data']['card']['id'])

  taskName = action['data']['card']['name']
  creatorName = action['memberCreator']['fullName']

  subject = "Trello: #{creatorName} added \"#{taskName}\""

  body = <<-eos
#{subject}

#{card_url}
eos

  send_email(subject, body)
end

set_latest_actions(cur_actions)
