require "savon"

Savon.configure do |config|
  config.logger = Rails.logger
end

HTTPI.log = false