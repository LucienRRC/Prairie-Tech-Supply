require "test_helper"

class StorefrontTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Test Gaming")
    @product = Product.create!(
      category: @category,
      name: "Test Mechanical Keyboard",
      brand: "Test Brand",
      sku: "TEST-KEY-001",
      price: 99.99,
      stock_quantity: 4,
      description: "A complete product description for storefront testing.",
      active: true
    )
    @paginated_products = 6.times.map do |index|
      Product.create!(
        category: @category,
        name: "Pagination Product #{format('%02d', index + 1)}",
        brand: "Test Brand",
        sku: "PAGE-#{format('%03d', index + 1)}",
        price: 19.99 + index,
        stock_quantity: 10,
        description: "A real product description used to verify Kaminari pagination.",
        active: true
      )
    end
    SitePage.create!(slug: "about", title: "About Test Store", body: "About page body.")
    SitePage.create!(slug: "contact", title: "Contact Test Store", body: "Contact page body.")
  end

  test "lists and shows active products" do
    get products_url
    assert_response :success
    assert_select "h3", text: @paginated_products.first.name
    assert_select "article.product-card", count: 6
    assert_select "nav.pagination"
    assert_select "h3", text: @product.name, count: 0

    get products_url(page: 2)
    assert_response :success
    assert_select "h3", text: @product.name
    assert_select "article.product-card", count: 1
    assert_select "h3", text: @paginated_products.first.name, count: 0

    get product_url(@product)
    assert_response :success
    assert_select "h1", text: @product.name
  end

  test "shows editable public pages" do
    get about_url
    assert_response :success
    assert_select "h1", text: "About Test Store"

    get contact_url
    assert_response :success
    assert_select "h1", text: "Contact Test Store"
  end

  test "searches titles and descriptions with an optional category" do
    office_category = Category.create!(name: "Test Office")
    office_product = Product.create!(
      category: office_category,
      name: "Office Docking Station",
      brand: "Prairie Tech",
      sku: "SEARCH-OFFICE-001",
      price: 129.99,
      stock_quantity: 8,
      description: "A complete portable Thunderbolt hub for a productive workspace.",
      active: true
    )
    inactive_product = Product.create!(
      category: office_category,
      name: "Archived Thunderbolt Adapter",
      brand: "Prairie Tech",
      sku: "SEARCH-INACTIVE-002",
      price: 59.99,
      stock_quantity: 3,
      description: "An inactive Thunderbolt product that should not appear in search.",
      active: false
    )

    get products_url(keyword: "mechanical")
    assert_response :success
    assert_select "form.product-search[role='search']" do
      assert_select "input[name='keyword'][value='mechanical']"
      assert_select "select[name='category_id']"
      assert_select "option[value='']", text: "All categories"
      assert_select "option[value='#{@category.id}']", text: @category.name
      assert_select "option[value='#{office_category.id}']", text: office_category.name
    end
    assert_select "h3", text: @product.name
    assert_select "h3", text: office_product.name, count: 0

    get products_url(keyword: "THUNDERBOLT")
    assert_response :success
    assert_select "h3", text: office_product.name
    assert_select "h3", text: inactive_product.name, count: 0

    get products_url(keyword: "complete")
    assert_response :success
    assert_select "h3", text: @product.name
    assert_select "h3", text: office_product.name

    get products_url(keyword: "complete", category_id: @category.id)
    assert_response :success
    assert_select "select[name='category_id'] option[value='#{@category.id}'][selected]"
    assert_select "h3", text: @product.name
    assert_select "h3", text: office_product.name, count: 0

    get products_url(keyword: "complete", category_id: office_category.id)
    assert_response :success
    assert_select "h3", text: office_product.name
    assert_select "h3", text: @product.name, count: 0

    get products_url(keyword: "no-such-product")
    assert_response :success
    assert_select ".empty-products", text: /No products found/
  end

  test "filters available products by new and recently updated" do
    old_product = Product.create!(
      category: @category,
      name: "Established Desktop Computer",
      brand: "Prairie Tech",
      sku: "FILTER-OLD-001",
      price: 799.99,
      stock_quantity: 3,
      description: "An established product outside both three-day filter windows.",
      active: true
    )
    recently_updated_product = Product.create!(
      category: @category,
      name: "Recently Refreshed Monitor",
      brand: "Prairie Tech",
      sku: "FILTER-UPDATED-002",
      price: 249.99,
      stock_quantity: 5,
      description: "An older product whose listing was recently updated.",
      active: true
    )
    unavailable_product = Product.create!(
      category: @category,
      name: "Unavailable New Accessory",
      brand: "Prairie Tech",
      sku: "FILTER-UNAVAILABLE-003",
      price: 29.99,
      stock_quantity: 0,
      description: "A new product that is not currently available.",
      active: true
    )

    old_product.update_columns(created_at: 5.days.ago, updated_at: 5.days.ago)
    recently_updated_product.update_columns(created_at: 5.days.ago, updated_at: 1.day.ago)

    get products_url(filter: "new", keyword: "keyboard")
    assert_response :success
    assert_select "select[name='filter']" do
      assert_select "option[value='']", text: "All products"
      assert_select "option[value='new'][selected]", text: "New arrivals (last 3 days)"
      assert_select "option[value='recently_updated']", text: "Recently updated (last 3 days)"
    end
    assert_select "input[name='keyword'][value='keyboard']"
    assert_select "h3", text: @product.name
    assert_select "h3", text: old_product.name, count: 0
    assert_select "h3", text: recently_updated_product.name, count: 0
    assert_select "h3", text: unavailable_product.name, count: 0

    get products_url(filter: "recently_updated", keyword: "refreshed")
    assert_response :success
    assert_select "option[value='recently_updated'][selected]"
    assert_select "h3", text: recently_updated_product.name
    assert_select "h3", text: old_product.name, count: 0
    assert_select "h3", text: unavailable_product.name, count: 0

    get products_url(filter: "new", category_id: @category.id, keyword: "keyboard")
    assert_response :success
    assert_select "input[name='keyword'][value='keyboard']"
    assert_select "option[value='#{@category.id}'][selected]"
    assert_select "option[value='new'][selected]"
    assert_select "h3", text: @product.name
  end

  test "navigates products through dedicated category pages" do
    office_category = Category.create!(name: "Category Navigation Office", description: "Office technology and accessories.")
    office_product = Product.create!(
      category: office_category,
      name: "Category Navigation Dock",
      brand: "Prairie Tech",
      sku: "CATEGORY-NAV-001",
      price: 89.99,
      stock_quantity: 7,
      description: "An active office product for testing category navigation.",
      active: true
    )
    inactive_product = Product.create!(
      category: @category,
      name: "Inactive Category Product",
      brand: "Prairie Tech",
      sku: "CATEGORY-INACTIVE-002",
      price: 39.99,
      stock_quantity: 2,
      description: "An inactive product that must not appear on category pages.",
      active: false
    )

    get categories_url
    assert_response :success
    assert_select "h1", text: "Categories"
    assert_select "a[href='#{category_path(@category)}']", text: /Browse #{@category.name}/
    assert_select "a[href='#{category_path(office_category)}']", text: /Browse #{office_category.name}/

    get category_url(@category)
    assert_response :success
    assert_select "h1", text: @category.name
    assert_select "form.product-search", count: 0
    assert_select "article.product-card", count: 6
    assert_select "h3", text: office_product.name, count: 0
    assert_select "h3", text: inactive_product.name, count: 0
    assert_select "nav.pagination"

    get category_url(@category, page: 2)
    assert_response :success
    assert_select "article.product-card", count: 1
    assert_select "h3", text: @product.name

    get category_url(office_category)
    assert_response :success
    assert_select "h3", text: office_product.name
    assert_select "h3", text: @product.name, count: 0
  end

  test "admin dashboard requires authentication" do
    get admin_root_url

    assert_redirected_to new_admin_user_session_url
  end
end
