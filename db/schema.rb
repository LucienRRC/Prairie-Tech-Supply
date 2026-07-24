# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_23_010000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "username", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_admin_users_on_username", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_carts_on_user_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.integer "province_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["province_id"], name: "index_customers_on_province_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.string "product_name", null: false
    t.string "sku", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "line_total", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id"
    t.string "status", default: "pending", null: false
    t.string "delivery_method", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "gst_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "pst_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "hst_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "delivery_fee", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "recipient_name", null: false
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.string "province_name", null: false
    t.decimal "gst_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.decimal "pst_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.decimal "hst_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id", null: false
    t.index ["customer_id", "created_at"], name: "index_orders_on_customer_id_and_created_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id", "created_at"], name: "index_orders_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pickup_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "order_id"
    t.string "pickup_type", null: false
    t.string "status", default: "requested", null: false
    t.datetime "scheduled_at", null: false
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_pickup_requests_on_order_id"
    t.index ["status", "scheduled_at"], name: "index_pickup_requests_on_status_and_scheduled_at"
    t.index ["user_id"], name: "index_pickup_requests_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "brand"
    t.string "sku", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "stock_quantity", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "sale_price", precision: 10, scale: 2
    t.index ["active", "category_id"], name: "index_products_on_active_and_category_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "provinces", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.decimal "gst_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.decimal "pst_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.decimal "hst_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_provinces_on_abbreviation", unique: true
    t.index ["name"], name: "index_provinces_on_name", unique: true
  end

  create_table "repair_requests", force: :cascade do |t|
    t.integer "pickup_request_id", null: false
    t.string "device_type", null: false
    t.string "brand"
    t.string "model"
    t.text "problem_description", null: false
    t.decimal "estimated_price", precision: 10, scale: 2
    t.string "repair_status", default: "submitted", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pickup_request_id"], name: "index_repair_requests_on_pickup_request_id", unique: true
  end

  create_table "site_pages", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_site_pages_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.integer "province_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.string "role", default: "customer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["province_id"], name: "index_users_on_province_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "customers", "provinces"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "users"
  add_foreign_key "pickup_requests", "orders"
  add_foreign_key "pickup_requests", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "repair_requests", "pickup_requests"
  add_foreign_key "users", "provinces"
end
