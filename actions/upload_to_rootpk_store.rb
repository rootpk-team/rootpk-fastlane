module Fastlane
  module Actions
    module SharedValues
      ROOTPK_PLATFORM = :ROOTPK_PLATFORM
      ROOTPK_PATH = :ROOTPK_PATH
      ROOTPK_APP_ID = :ROOTPK_APP_ID
      ROOTPK_APP_SECRET_KEY = :ROOTPK_APP_SECRET_KEY
      ROOTPK_UPLOAD_URL = :ROOTPK_UPLOAD_URL
    end

    class UploadToRootpkStoreAction < Action
      def self.run(options)
        require 'net/http'
        require 'net/http/post/multipart'
        require 'uri'
        require 'json'

        Actions.lane_context[SharedValues::ROOTPK_PATH] = options[:path]
        Actions.lane_context[SharedValues::ROOTPK_APP_ID] = options[:app_id]
        Actions.lane_context[SharedValues::ROOTPK_APP_SECRET_KEY] = options[:secret_key]

        params = {
          file: UploadIO.new(options[:path], get_file_mimetype(options)),
          appId: options[:app_id],
          secretKey: options[:secret_key]
        }

        uri = URI.parse(upload_url(options))
        req = create_request(uri, params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        UI.message("Uploading #{get_file_type(options)} to the Rootpk Store... this might take a while")

        response = http.request(req)

        parse_response(response)

        UI.success("#{get_file_type(options)} successfully uploaded to the Rootpk Store")
      end

      def self.get_file_mimetype(options)
        if options[:platform] == 'android'
          'application/vnd.android.package-archive'
        else
          'application/octet-stream'
        end
      end
      private_class_method :get_file_mimetype

      def self.get_file_type(options)
        if options[:platform] == 'android'
          'APK'
        else
          'IPA'
        end
      end
      private_class_method :get_file_type

      def self.upload_url(options)
        default_url = if options[:platform] == 'android'
                        'https://api.rootpk.com/apk/upload'
                      else
                        'https://api.rootpk.com/ipa/upload'
                      end
      
        upload_url = ENV['ROOTPK_UPLOAD_URL'] || default_url
        Actions.lane_context[SharedValues::ROOTPK_UPLOAD_URL] = upload_url
        upload_url
      end
      private_class_method :upload_url

      def self.create_request(uri, params)
        req = Net::HTTP::Post::Multipart.new(uri.path, params)
        req
      end
      private_class_method :create_request

      def self.parse_response(response)
        if !(response.kind_of?(Net::HTTPOK))
          raise "Server response not ok"
        end
        return true;
      rescue => ex
        UI.error(ex)
        UI.user_error!("Error uploading to the Rootpk Store: #{response.body}")
      end
      private_class_method :parse_response

      def self.description
        "Upload your APK or IPA to the [Rootpk Store](https://rootpk.com)"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: "ROOTPK_PLATFORM",
                                       description: "Platform (android or ios)",
                                       verify_block: proc do |value|
                                         UI.user_error!("No platform given, pass using `platform: 'your_platform'`") unless ['android', 'ios'].include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "ROOTPK_PATH",
                                       description: "Path to APK or IPA build on the local filesystem",
                                       verify_block: proc do |value|
                                         UI.user_error!("No path given, pass using `path: 'your_path'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_id,
                                       env_name: "ROOTPK_APP_ID",
                                       sensitive: true,
                                       description: "Rootpk app id",
                                       verify_block: proc do |value|
                                         UI.user_error!("No app id given, pass using `app_id: 'your_app_id'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :secret_key,
                                       env_name: "ROOTPK_APP_SECRET_KEY",
                                       sensitive: true,
                                       description: "Rootpk app secret key",
                                       verify_block: proc do |value|
                                         UI.user_error!("No app secret key given, pass using `secret_key: 'your_app_secret_key'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :upload_url,
                                       env_name: "ROOTPK_UPLOAD_URL",
                                       description: "Rootpk upload URL"),
        ]
      end

      def self.authors
        ["rootpk-team"]
      end

      def self.is_supported?(platform)
        [:android, :ios].include?(platform)
      end

      def self.example_code
        [
          'upload_to_rootpk_store(
            platform: "android",
            path: "myapp.apk",
            app_id: "your_app_id",
            secret_key: "your_app_secret_key",
          )',
        ]
      end
    end
  end
end
