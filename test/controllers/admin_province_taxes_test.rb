require "test_helper"

class AdminProvinceTaxesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = AdminUser.create!(
      username: "province_tax_admin",
      email: "province-tax-admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @province = Province.create!(
      name: "Tax Test Province",
      abbreviation: "TP",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    sign_in @admin
  end

  test "administrator lists and edits province tax rates without changing its identity" do
    get admin_provinces_path

    assert_response :success
    assert_select "h2", text: "Canadian Province and Territory Tax Rates"
    assert_select "tr#province_#{@province.id}", text: /Tax Test Province.*TP.*5%.*7%.*0%/m
    assert_select "a[href*='.csv'], a[href*='.xml'], a[href*='.json']", count: 0
    assert_select "a[href='#{edit_admin_province_path(@province)}']", text: "Edit tax rates"

    get edit_admin_province_path(@province)

    assert_response :success
    assert_select "input[name='province[name]'][disabled]"
    assert_select "input[name='province[abbreviation]'][disabled]"
    assert_select "input[name='province[gst_rate]']"
    assert_select "input[name='province[pst_rate]']"
    assert_select "input[name='province[hst_rate]']"
    assert_select ".inline-hints", text: /0\.05 for 5%/

    patch admin_province_path(@province), params: {
      province: {
        name: "Attempted Rename",
        abbreviation: "XX",
        gst_rate: "0.06",
        pst_rate: "0.08",
        hst_rate: "0"
      }
    }

    assert_redirected_to admin_provinces_path
    @province.reload
    assert_equal "Tax Test Province", @province.name
    assert_equal "TP", @province.abbreviation
    assert_equal BigDecimal("0.06"), @province.gst_rate
    assert_equal BigDecimal("0.08"), @province.pst_rate
    assert_equal BigDecimal("0"), @province.hst_rate
  end

  test "province creation and deletion are not available" do
    post admin_provinces_path
    assert_response :not_found

    delete admin_province_path(@province)
    assert_response :not_found
  end

  test "customer cannot access province tax management" do
    sign_out @admin

    get admin_provinces_path

    assert_redirected_to new_admin_user_session_path
  end
end
