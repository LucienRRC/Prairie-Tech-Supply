require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    category = Category.create!(name: "Session Cart Products")
    @keyboard = Product.create!(
      category: category,
      name: "Session Cart Keyboard",
      brand: "Prairie Tech",
      sku: "CART-KEYBOARD-001",
      price: 100,
      sale_price: 80,
      stock_quantity: 5,
      description: "A keyboard used to verify the session shopping cart.",
      active: true
    )
    @mouse = Product.create!(
      category: category,
      name: "Session Cart Mouse",
      brand: "Prairie Tech",
      sku: "CART-MOUSE-002",
      price: 40,
      stock_quantity: 3,
      description: "A mouse used to verify multiple session cart products.",
      active: true
    )
    @unavailable = Product.create!(
      category: category,
      name: "Unavailable Session Product",
      brand: "Prairie Tech",
      sku: "CART-UNAVAILABLE-003",
      price: 20,
      stock_quantity: 0,
      description: "An unavailable product that cannot be added to a cart.",
      active: true
    )
  end

  test "stores multiple products and quantities in the session cart" do
    post add_cart_item_path(@keyboard), params: { quantity: 2 }
    assert_redirected_to cart_path

    post add_cart_item_path(@mouse), params: { quantity: 1 }
    assert_redirected_to cart_path

    get cart_path
    assert_response :success
    assert_select "article.cart-item", count: 2
    assert_select "h2", text: @keyboard.name
    assert_select "h2", text: @mouse.name
    assert_select ".cart-count", text: "3"
    assert_select ".cart-summary", text: /\$200\.00/
    assert_select "input#quantity_#{@keyboard.id}[value='2']"
    assert_select "input#quantity_#{@mouse.id}[value='1']"
  end

  test "updates and removes session cart products" do
    post add_cart_item_path(@keyboard), params: { quantity: 1 }
    patch update_cart_item_path(@keyboard), params: { quantity: 4 }, as: :json
    assert_response :success
    response_data = response.parsed_body
    assert_equal 4, response_data["quantity"]
    assert_equal "320.0", response_data["line_total"].to_s
    assert_equal "320.0", response_data["subtotal"].to_s
    assert_equal 4, response_data["item_count"]

    get cart_path
    assert_select "input#quantity_#{@keyboard.id}[value='4']"
    assert_select "input#quantity_#{@keyboard.id}[type='number'][min='1'][max='5']"
    assert_select ".cart-count", text: "4"
    assert_select "form.cart-quantity-form[action='#{update_cart_item_path(@keyboard)}'][data-auto-cart-form][data-unit-price='80.0']"
    assert_select "form.cart-remove-form[action='#{remove_cart_item_path(@keyboard)}']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button.cart-remove-button", text: "Remove"
    end
    assert_select "[data-line-total]", text: "$320.00"
    assert_select "input[type='submit'][value='Update']", count: 0

    patch update_cart_item_path(@keyboard), params: { quantity: 0 }, as: :json
    assert_response :success
    assert_equal 1, response.parsed_body["quantity"]

    get cart_path
    assert_select "h2", text: @keyboard.name
    assert_select "input#quantity_#{@keyboard.id}[value='1']"

    delete remove_cart_item_path(@keyboard)
    assert_redirected_to cart_path

    get cart_path
    assert_response :success
    assert_select ".empty-cart", text: /Your cart is empty/
    assert_select ".cart-count", text: "0"
  end

  test "caps quantities at stock and rejects unavailable products" do
    post add_cart_item_path(@mouse), params: { quantity: 99 }
    get cart_path
    assert_select "input#quantity_#{@mouse.id}[value='3']"
    assert_select ".cart-count", text: "3"

    post add_cart_item_path(@unavailable), params: { quantity: 1 }
    assert_redirected_to products_path
    follow_redirect!
    assert_select ".alert", text: "That product is not currently available."
  end
end
