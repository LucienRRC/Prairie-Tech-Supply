ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module StripeCheckoutTestHelper
  def submit_checkout(params = nil, **keywords)
    params ||= keywords
    fake_creator = lambda do |order:, **|
      Stripe::Checkout::Session.construct_from(
        id: "cs_test_order_#{order.id}",
        url: stripe_checkout_url(order)
      )
    end

    StripeCheckoutSession.stub(:create, fake_creator) do
      post checkout_path, params: params
    end
  end

  def stripe_checkout_url(order)
    "https://checkout.stripe.test/orders/#{order.id}"
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
