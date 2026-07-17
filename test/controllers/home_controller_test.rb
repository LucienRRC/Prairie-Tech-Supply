require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Front Page Category", description: "Products displayed from the front page.")
    @available_product = Product.create!(
      category: @category,
      name: "Front Page Available Product",
      brand: "Prairie Tech",
      sku: "FRONT-AVAILABLE-001",
      price: 79.99,
      stock_quantity: 5,
      description: "An active in-stock product that customers can reach from the front page.",
      active: true
    )
    @out_of_stock_product = Product.create!(
      category: @category,
      name: "Front Page Out of Stock Product",
      brand: "Prairie Tech",
      sku: "FRONT-EMPTY-002",
      price: 49.99,
      stock_quantity: 0,
      description: "An out-of-stock product that is not currently available.",
      active: true
    )
    @inactive_product = Product.create!(
      category: @category,
      name: "Front Page Inactive Product",
      brand: "Prairie Tech",
      sku: "FRONT-INACTIVE-003",
      price: 39.99,
      stock_quantity: 4,
      description: "An inactive product that must not appear on the front page.",
      active: false
    )
  end

  test "shows the storefront home page" do
    get root_url

    assert_response :success
    assert_select "h1", "Technology that works for Winnipeg."
    assert_select "a[href='#{products_path}']", text: /Browse products/
    assert_select "a[href='#{categories_path}']", text: /Shop by category/
    assert_select "a[href='#{category_path(@category)}']", text: /#{@category.name}/
    assert_select "a[href='#{product_path(@available_product)}']", minimum: 1
    assert_select "h3", text: @available_product.name
    assert_select "h3", text: @out_of_stock_product.name, count: 0
    assert_select "h3", text: @inactive_product.name, count: 0
  end
end
