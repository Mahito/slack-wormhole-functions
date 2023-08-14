# frozen_string_literal: true

require_relative 'storage'

module SlackWormhole
  module Storage
    # Share file on slack
    class Slack < Storage

      # @return [String] the url of the file
      def shared_url
        payload = {
          file: @id
        }

        res = slack_user.files_sharedPublicURL(payload)
        res['file']['permalink_public']
      end
    end
  end
end
