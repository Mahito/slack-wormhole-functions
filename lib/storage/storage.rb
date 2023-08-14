# frozen_string_literal: true

require_relative '../utils'

module SlackWormhole
  module Storage
    class Storage

      def initialize(file)
        @id = file['id']
        @name = file['name']
        @download_url = file['url_private_download']
      end

      def shared_url
        raise NotImplementError, "#{self.class}#shared_url is not implemented"
      end
    end
  end
end
