require "test_helper"

class CustomerAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @province = Province.create!(
      name: "Authentication Manitoba",
      abbreviation: "AM",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
  end

  test "customer signs up with a hashed password and stays logged in across requests" do
    get new_customer_registration_path
    assert_response :success
    assert_select "form.auth-form[action='#{customer_registration_path}']"
    assert_select "input[name='customer[username]']"
    assert_select "input[name='customer[password]'][type='password']"
    assert_select "select[name='customer[province_id]']"

    assert_difference "Customer.count", 1 do
      post customer_registration_path, params: {
        customer: {
          username: "prairie_customer",
          first_name: "Prairie",
          last_name: "Customer",
          email: "prairie.customer@example.com",
          address: "100 Main Street",
          city: "Winnipeg",
          postal_code: "R3C 1A1",
          province_id: @province.id,
          password: "secure-password",
          password_confirmation: "secure-password"
        }
      }
    end

    customer = Customer.find_by!(username: "prairie_customer")
    assert customer.account_registered?
    assert_not_equal "secure-password", customer.encrypted_password
    assert customer.encrypted_password.start_with?("$2")
    assert customer.valid_password?("secure-password")
    assert_not Customer.devise_modules.include?(:rememberable)

    assert_redirected_to root_path
    follow_redirect!
    assert_select "a[href='#{edit_customer_registration_path}']", text: "Account"
    assert_select "form[action='#{destroy_customer_session_path}'] button", text: "Log out"

    get products_path
    assert_response :success
    assert_select "a[href='#{edit_customer_registration_path}']", text: "Account"
  end

  test "customer logs out and logs back in using username and password" do
    customer = Customer.create!(
      username: "returning_customer",
      first_name: "Returning",
      last_name: "Customer",
      email: "returning@example.com",
      province: @province,
      account_registered: true,
      password: "login-password",
      password_confirmation: "login-password"
    )
    post customer_session_path, params: {
      customer: { username: customer.username, password: "login-password" }
    }
    assert_redirected_to root_path

    get root_path
    assert_select "a[href='#{edit_customer_registration_path}']", text: "Account"

    delete destroy_customer_session_path
    assert_redirected_to root_path
    follow_redirect!
    assert_select "a[href='#{new_customer_session_path}']", text: "Log in"
    assert_select "a[href='#{edit_customer_registration_path}']", count: 0

    post customer_session_path, params: {
      customer: { username: customer.username, password: "wrong-password" }
    }
    assert_response :unprocessable_entity
    assert_select ".alert", text: /Invalid username or password/i
  end

  test "registered customer address prefills checkout and is saved with the order" do
    customer = Customer.create!(
      username: "checkout_customer",
      first_name: "Checkout",
      last_name: "Customer",
      email: "account.checkout@example.com",
      address: "12 Old Address",
      city: "Winnipeg",
      postal_code: "R2C 2A2",
      province: @province,
      account_registered: true,
      password: "checkout-password",
      password_confirmation: "checkout-password"
    )
    category = Category.create!(name: "Account Checkout")
    product = Product.create!(
      category: category,
      name: "Account Checkout Product",
      sku: "ACCOUNT-CHECKOUT-001",
      price: 50,
      stock_quantity: 4,
      active: true
    )

    post customer_session_path, params: {
      customer: { username: customer.username, password: "checkout-password" }
    }
    post add_cart_item_path(product), params: { quantity: 1 }

    get new_checkout_path
    assert_response :success
    assert_select "input[name='customer[first_name]'][value='Checkout']"
    assert_select "input[name='customer[email]'][value='account.checkout@example.com'][readonly]"
    assert_select "input[name='customer[address]'][value='12 Old Address']"

    post checkout_path, params: {
      customer: {
        first_name: "Checkout",
        last_name: "Customer",
        email: "attempted-change@example.com",
        address: "99 New Address",
        city: "Winnipeg",
        postal_code: "R3C 3B3",
        province_id: @province.id
      }
    }

    order = Order.order(:id).last
    assert_redirected_to order_path(order)
    assert_equal customer, order.customer
    assert_equal "account.checkout@example.com", customer.reload.email
    assert_equal "99 New Address", customer.address
    assert_equal "99 New Address", order.address
  end

  test "registration claims an existing guest customer without losing orders" do
    guest = Customer.create!(
      first_name: "Former",
      last_name: "Guest",
      email: "former.guest@example.com",
      province: @province
    )

    assert_no_difference "Customer.count" do
      post customer_registration_path, params: {
        customer: {
          username: "former_guest",
          first_name: "Former",
          last_name: "Guest",
          email: "former.guest@example.com",
          province_id: @province.id,
          password: "claimed-password",
          password_confirmation: "claimed-password"
        }
      }
    end

    assert_redirected_to root_path
    assert guest.reload.account_registered?
    assert_equal "former_guest", guest.username
    assert guest.valid_password?("claimed-password")
  end
end
