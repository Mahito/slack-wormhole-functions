# frozen_string_literal: true

require 'base64'
require 'google/cloud/datastore'
require 'google/cloud/pubsub'
require 'google/cloud/secret_manager'
require 'json'
require 'slack-ruby-client'

def slack_api_token(secret)
  client = Google::Cloud::SecretManager.secret_manager_service
  key = client.secret_version_path(project: ENV['GCP_PROJECT'],
                                   secret: secret,
                                   secret_version: 'latest')

  client.access_secret_version(name: key).payload.data
end

def logger
  @logger ||= Logger.new($stdout)
end

def datastore
  if @datastore
    @datastore
  elsif ENV['GOOGLE_APPLICATION_CREDENTIALS']
    @datastore = Google::Cloud::Datastore.new(
      project_id: ENV['GCP_PROJECT'],
      credentials: ENV['GOOGLE_APPLICATION_CREDENTIALS']
    )
  else
    @datastore = Google::Cloud::Datastore.new(project_id: ENV['GCP_PROJECT'])
  end
end

def pubsub
  if @pubsub
    @pubsub
  elsif ENV['GOOGLE_APPLICATION_CREDENTIALS']
    @pubsub = Google::Cloud::Pubsub.new(
      project_id: ENV['GCP_PROJECT'],
      credentials: ENV['GOOGLE_APPLICATION_CREDENTIALS']
    )
  else
    @pubsub = Google::Cloud::Pubsub.new(project_id: ENV['GCP_PROJECT'])
  end
end

def topic
  @topic ||= pubsub.topic(ENV['WORMHOLE_TOPIC_NAME'])
end

def query
  datastore.query(ENV['WORMHOLE_ENTITY_NAME'])
end

def web
  @web ||= Slack::Web::Client.new(token: slack_api_token(ENV['BOT_TOKEN_NAME']))
end

def slack_user
  @slack_user ||= Slack::Web::Client.new(token: slack_api_token(ENV['USER_TOKEN_NAME']))
end

def channel(id)
  web.conversations_info(channel: id).channel
end

def user(id)
  web.users_info(user: id).user if id
end

def username(user)
  username = user.profile.display_name
  username = user.real_name if username.empty?
  username = user.name if username.empty?
  username
end
