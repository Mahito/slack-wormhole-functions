# frozen_string_literal: true

require 'functions_framework'
require_relative 'lib/event_handler'

FunctionsFramework.http 'recieve_slack_event' do |request|
  data = JSON.parse(request.body.read)
  method = data['type']
  event_id = data['event_id']
  request.logger.info "Event ID: #{event_id}, Type is #{method}"

  if method == 'event_callback'
    data = data['event']
    data['event_id'] = event_id
    method = data['type']
    request.logger.info "Event type :#{method}"
  end

  SlackWormhole::EventHandler.send(method, data) if SlackWormhole::EventHandler.respond_to?(method)
end
