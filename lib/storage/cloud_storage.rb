# frozen_string_literal: true

require 'googleauth'
require 'google/apis/iamcredentials_v1'
require 'google/cloud/storage'

require_relative 'storage'

module SlackWormhole
  module Storage
    # Share file on slack
    class CloudStorage < Storage

      def initialize(file)
        super(file)

        if ENV['GOOGLE_APPLICATION_CREDENTIALS']
          @storage = Google::Cloud::Storage.new(
            project_id: ENV['GCP_PROJECT'],
            credentials: ENV['GOOGLE_APPLICATION_CREDENTIALS']
          )
        else
          @storage = Google::Cloud::Storage.new(
            project_id: ENV['GCP_PROJECT']
          )
        end
        @issuer = ENV['GCP_ISSUER']
      end

      # @return [String] the url of the file
      def shared_url
        # Upload file to cloud storage
        upload_file

        # Get the file to download
        file = @storage.bucket('slack-wormhole').file @id

        # Generate a signed URL for the file that expires in a week.
        url = file.signed_url method: 'GET',
          expires: 60 * 60 * 24 * 7,  # 7 days
          issuer: @issuer, signer: signer,
          version: :v4

        return "<#{url}|#{@name}>\n"
      end

      private

      def download_file
        @file_path = "/tmp/#{@name}"
        blob = URI.open(@download_url, {
          'Authorization' => "Bearer #{web.token}"
        }) { |file| file.read }
        File.open(@file_path, 'wb') do |file|
          file.write(blob)
        end
      end

      def upload_file
        download_file

        bucket = @storage.bucket 'slack-wormhole'
        bucket.create_file @file_path, @id
        delete_file # delete file after upload
      end

      def delete_file
        File.delete @file_path if File.exist? @file_path
      end

      # @return [Proc] the signer
      def signer
        # Create a lambda that accepts the string_to_sign
        lambda do |string_to_sign|
          iam_credentials = Google::Apis::IamcredentialsV1
          iam_client = iam_credentials::IAMCredentialsService.new

          # Get the environment configured authorization
          scopes = ["https://www.googleapis.com/auth/iam"]
          iam_client.authorization = Google::Auth.get_application_default scopes

          request = iam_credentials::SignBlobRequest.new(
            payload: string_to_sign
          )
          resource = "projects/-/serviceAccounts/#{@issuer}"
          response = iam_client.sign_service_account_blob resource, request
          response.signed_blob
        end
      end
    end
  end
end
