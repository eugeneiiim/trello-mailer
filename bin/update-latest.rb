require 'rubygems'
require 'json'
require 'redis'
require "net/https"
require 'pony'

ruri = URI.parse(ENV['REDISTOGO_URL'])
REDIS = Redis.new(:host => ruri.host, :port => ruri.port, :password => ruri.password)

ACTIONS_KEY = "#{ENV['TRELLO_BOARD_ID']}:actions"

def get_raw(url_str)
  uri = URI.parse(url_str)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  http.request(request).body
end

def get_json(url_str)
  JSON.parse(get_raw(url_str))
end

def get_actions
  get_json("https://api.trello.com/1/boards/#{ENV['TRELLO_BOARD_ID']}/actions?key=#{ENV['TRELLO_KEY']}&token=#{ENV['TRELLO_TOKEN']}&filter=createCard")
end

def get_card_url(id)
  get_json("https://api.trello.com/1/cards/#{id}?key=#{ENV['TRELLO_KEY']}&token=#{ENV['TRELLO_TOKEN']}&fields=url")['url']
end

def get_prev_actions
  prev_json = REDIS.get(ACTIONS_KEY) || '[]'
  JSON.parse(prev_json)
end

def send_email(recip, subject, body)
  puts "Sending #{subject} to #{ENV['EMAIL_ADDR']}..."
  Pony.mail(:to => recip,
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

def post_flowdock(flowdock_token, subject, from_address, content, link, from_name)
  url_str = "https://api.flowdock.com/v1/messages/team_inbox/#{flowdock_token}"
  url = URI.parse(url_str)
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({:subject => subject, :from_address => from_address, :source => 'Trello', :content => content, :link => link, :from_name => from_name })
  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  resp = res.start {|http| http.request(req) }
  puts resp.body
end

prev_actions = get_prev_actions()
cur_actions = get_actions()
new_actions = cur_actions - prev_actions

puts "Sending emails for #{new_actions.length} new actions."

new_actions.each do |action|
  card_url = get_card_url(action['data']['card']['id'])
  taskName = action['data']['card']['name']
  creatorName = action['memberCreator']['fullName']

  subject = "New card: \"#{taskName}\""

  body = <<-eos
#{creatorName} added \"#{taskName}\".
<br />
#{card_url}
eos

  if ENV['EMAIL_ADDR']
    send_email(ENV['EMAIL_ADDR'], subject, body)
  end

  if ENV['FLOWDOCK_TOKEN']
    from_email = 'do-not-reply@trello.com' # TODO  get_user_email(action['id'])
    post_flowdock(ENV['FLOWDOCK_TOKEN'], subject, from_email, body, card_url, creatorName)
  end
end

REDIS.set(ACTIONS_KEY, cur_actions.to_json)
