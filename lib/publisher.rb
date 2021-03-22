# frozen_string_literal: true

require_relative 'utils'

# Top Level module
module SlackWormhole
  # Event reciever
  module Publisher
    class << self
      def publish(payload, event_id)
        replace_username(payload) if payload[:text]
        json = JSON.dump(payload)
        data = Base64.strict_encode64(json)

        task = nil
        datastore.transaction do |tx|
          task = tx.find event_id
          if task.nil?
            topic.publish(data)
            task = datastore.entity event_id do |t|
              t['state'] = 'published'
            end
            tx.save task
            logger.info("Message has been published - Action[#{payload[:action]}]")
          end
        end
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
