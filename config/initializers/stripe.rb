Rails.application.config.x.stripe.secret_key =
  ENV["STRIPE_SECRET_KEY"].presence || Rails.application.credentials.dig(:stripe, :secret_key)
Rails.application.config.x.stripe.webhook_secret =
  ENV["STRIPE_WEBHOOK_SECRET"].presence || Rails.application.credentials.dig(:stripe, :webhook_secret)
Rails.application.config.x.stripe.checkout_enabled =
  ActiveModel::Type::Boolean.new.cast(ENV.fetch("STRIPE_CHECKOUT_ENABLED", false))

Stripe.api_key = Rails.application.config.x.stripe.secret_key if Rails.application.config.x.stripe.secret_key.present?
