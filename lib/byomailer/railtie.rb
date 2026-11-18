module Byomailer
  # Reads Rails.application.credentials.byomailer.
  #
  #   # bin/rails credentials:edit
  #   byomailer:
  #     url: https://mail.example.com
  #     token: ...
  #     webhook_secret: whsec_...
  #
  # An initializer that calls Byomailer.configure runs later and wins.
  class Railtie < Rails::Railtie
    initializer "byomailer.credentials", before: :load_config_initializers do |app|
      if (credentials = app.credentials.byomailer)
        Byomailer.config.merge!(credentials)
        Byomailer.reset!
      end
    end
  end
end
