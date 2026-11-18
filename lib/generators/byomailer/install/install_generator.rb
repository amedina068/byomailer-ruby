require "rails/generators/base"

module Byomailer
  module Generators
    # bin/rails generate byomailer:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Writes config/initializers/byomailer.rb"

      def copy_initializer
        template "byomailer.rb", "config/initializers/byomailer.rb"
      end

      def show_credentials
        say <<~TEXT

          Add the settings of your BYOMailer instance to the credentials:

            bin/rails credentials:edit

            byomailer:
              url: https://mail.example.com
              token: your-api-token
              webhook_secret: your-webhook-secret

        TEXT
      end
    end
  end
end
