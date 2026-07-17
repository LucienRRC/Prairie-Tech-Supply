require_relative "boot"

require "active_model"
require "active_model/callbacks"
require "active_model/validator"
require "active_model/validations/helper_methods"
require "active_model/validations/absence"
require "active_model/validations/acceptance"
require "active_model/validations/callbacks"
require "active_model/validations/comparison"
require "active_model/validations/confirmation"
require "active_model/validations/exclusion"
require "active_model/validations/format"
require "active_model/validations/inclusion"
require "active_model/validations/length"
require "active_model/validations/numericality"
require "active_model/validations/presence"
require "active_model/validations/validates"
require "active_model/validations/with"
require "active_model/validations"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PrairieTechSupply
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Central Time (US & Canada)"

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
