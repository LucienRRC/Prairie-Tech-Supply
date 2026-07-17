require "test_helper"

class CommerceCoreTest < ActiveSupport::TestCase
  test "a valid product belongs to a category" do
    category = Category.new(name: "Gaming")
    product = Product.new(
      category: category,
      name: "Mechanical Keyboard",
      sku: "KEY-001",
      price: 89.99,
      stock_quantity: 10
    )

    assert category.valid?
    assert product.valid?
  end

  test "cart item quantity must be positive" do
    cart_item = CartItem.new(quantity: 0)

    assert_not cart_item.valid?
    assert_includes cart_item.errors[:quantity], "must be greater than 0"
  end
end
