# frozen_string_literal: true

require_relative 'storage/cloud_storage'
require_relative 'publisher'
require_relative 'utils'

# Top Level module
module SlackWormhole
  # Event reciever
  module EventHandler
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
          logger.info("Subtype is #{data['subtype']}")
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

        Publisher.publish(payload, data['event_id'])
      end

      def message_deleted(data)
        payload = {
          room: channel(data['channel']).name,
          action: 'delete',
          timestamp: data['deleted_ts']
        }

        Publisher.publish(payload, data['event_id'])
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

      def bot_message(data)
        'SKIP'
      end

      def file_share(data)
        post_files(data)
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

        Publisher.publish(payload, data['event_id'])

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

        Publisher.publish(payload, data['event_id'])

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

        Publisher.publish(payload, data['event_id'])
      end

      def post_files(data)
        data['files'].each do |f|
          storage = Storage::CloudStorage.new(f)

          # 共有用画像の URL を text に追加
          data['text'] += "\n#{storage.shared_url}"
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

        Publisher.publish(payload, data['event_id'])
      end

      def delete_message(data)
        payload = {
          room: channel(data['channel']).name,
          action: 'delete',
          timestamp: data['deleted_ts']
        }

        Publisher.publish(payload, data['event_id'])
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

        Publisher.publish(payload, data['event_id'])
      end
    end
  end
end
