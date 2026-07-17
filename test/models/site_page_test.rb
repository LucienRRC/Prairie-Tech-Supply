require "test_helper"

class SitePageTest < ActiveSupport::TestCase
  test "only the about and contact slugs are accepted" do
    page = SitePage.new(slug: "other", title: "Other", body: "Body")

    assert_not page.valid?
    assert_includes page.errors[:slug], "is not included in the list"
  end
end
