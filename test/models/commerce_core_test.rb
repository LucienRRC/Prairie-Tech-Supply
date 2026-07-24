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

  test "sale price must be lower than the regular price" do
    category = Category.create!(name: "Sale Validation")
    product = Product.new(
      category: category,
      name: "Sale Product",
      sku: "SALE-VALIDATION-001",
      price: 100,
      sale_price: 100,
      stock_quantity: 5
    )

    assert_not product.valid?
    assert_includes product.errors[:sale_price], "must be less than 100.0"

    product.sale_price = 79.99
    assert product.valid?
    assert product.on_sale?
  end
end
