module Customers
  class RegistrationsController < Devise::RegistrationsController
    protected

    def build_resource(attributes = nil)
      attributes ||= {}
      normalized_email = attributes[:email].to_s.strip.downcase
      guest_customer = resource_class.find_by(
        email: normalized_email,
        account_registered: false
      )

      self.resource = guest_customer || resource_class.new
      resource.assign_attributes(attributes)
      resource.account_registered = true
    end
  end
end
