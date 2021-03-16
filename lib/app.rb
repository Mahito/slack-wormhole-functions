# frozen_string_literal: true

require 'functions_framework'
require_relative 'utils'

FunctionsFramework.http 'recieve_slack_event' do |request|
  data = JSON.parse(request.body.read)
  method = data['type']
  request.logger.info "Type is #{method}"

  if method == 'event_callback'
    data = data['event']
    method = data['type']
    request.logger.info "Event type is #{method}"
  end

  SlackWormhole::Reciever.send(method, data) if SlackWormhole::Reciever.respond_to?(method)
end

# Top Level module
module SlackWormhole
  # Event reciever
  module Reciever
    class << self
      def url_verification(data)
        data['challenge']
      end

      def message(data)
        res = { 'type': 'message' }
        if data['subtype'].nil?
          if data['files']
            post_files(data)
            res['files'] = true
          elsif data['thread_ts']
            post_reply(data)
            res['thread_ts'] = true
          else
            post_message(data)
          end
        else
          send(data['subtype'], data)
          res['subtype'] = data['subtype']
        end
        JSON.dump(res)
      end

      def message_changed(data)
        payload = {
          action: 'update',
          room: channel(data['channel']).name,
          timestamp: data['message']['ts'],
          text: data['message']['text']
        }

        publish(payload)
      end

      def message_deleted(data)
        payload = {
          room: channel(data['channel']).name,
          action: 'delete',
          timestamp: data['deleted_ts']
        }

        publish(payload)
      end

      def channel_join(data)
        if (user = user(data['user']))
          name = username(user)
          data['text'].sub!(/<.+>/, name)
          data['user'] = nil
        end
        post_message(data)
      end
      alias channel_leave channel_join

      def thread_broadcast(data)
        return unless data['bot_id'].nil?

        data['reply_broadcast'] = true
        post_reply(data)
      end

      def reaction_added(data)
        user = user(data['user'])
        name = username(user)
        icon = user.profile.image_192

        payload = {
          action: 'reaction_add', timestamp: data['ts'],
          thread_ts: data['item']['ts'],
          room: channel(data['item']['channel']).name,
          userid: data['user'], username: name,
          icon_url: icon, reaction: data['reaction']
        }

        q = query.where('timestamp', '=', payload[:thread_ts]).limit(1)
        datastore.run(q).each do |task|
          payload[:thread_ts] = task['originalTs']
        end

        publish(payload)

        JSON.dump({ 'type': 'reaction_added' })
      end

      def reaction_removed(data)
        user = user(data['user'])
        name = username(user)
        payload = {
          action: 'reaction_remove',
          room: channel(data['item']['channel']).name,
          userid: data['user'], username: name,
          reaction: data['reaction'], timestamp: data['item']['ts']
        }

        publish(payload)

        JSON.dump({ 'type': 'reaction_removed' })
      end

      def post_message(data)
        if (user = user(data['user']))
          name = username(user)
          icon = user.profile.image_192
        end

        payload = {
          action: 'post', timestamp: data['ts'],
          room: channel(data['channel']).name,
          username: name, icon_url: icon, text: data['text']
        }

        publish(payload)
      end

      def post_files(data)
        data['files'].each do |f|
          payload = {
            file: f['id']
          }

          res = web.files_sharedPublicURL(payload)
          data['text'] += "\n#{res['file']['permalink_public']}"
        end
        post_message(data)
      end

      def edit_message(data)
        payload = {
          action: 'update',
          room: channel(data['channel']).name,
          timestamp: data['message']['ts'],
          text: data['message']['text']
        }

        publish(payload)
      end

      def delete_message(data)
        payload = {
          room: channel(data['channel']).name,
          action: 'delete',
          timestamp: data['deleted_ts']
        }

        publish(payload)
      end

      def post_reply(data)
        user = user(data['user'])
        name = username(user)
        icon = user.profile.image_192

        payload = {
          action: 'post_reply', thread_ts: data['thread_ts'],
          timestamp: data['ts'],
          room: channel(data['channel']).name,
          username: name, icon_url: icon,
          text: data['text'], reply_broadcast: data['reply_broadcast']
        }

        q = query.where('timestamp', '=', data['thread_ts']).limit(1)
        datastore.run(q).each do |task|
          payload[:thread_ts] = task['originalTs']
        end

        publish(payload)
      end

      def publish(payload)
        replace_username(payload) if payload[:text]
        json = JSON.dump(payload)
        data = Base64.strict_encode64(json)
        topic.publish(data)
        logger.info("Message has been published - Action[#{payload[:action]}]")
      rescue Google::Cloud::InvalidArgumentError => e
        logger.error(e)
        error_payload = {
          channel: payload[:room],
          text: "Error - #{e.message}",
          as_user: false
        }
        web.chat_postMessage(error_payload)
      rescue StandardError => e
        logger.error(e)
        sleep 5
        retry
      end

      def replace_username(payload)
        text = payload[:text]
        while (match = text[/<@([UW].*?)>/, 1])
          text.sub!("<@#{match}>", "@#{username(user(match))}")
        end
        payload[:text] = text
      end
    end
  end
end
