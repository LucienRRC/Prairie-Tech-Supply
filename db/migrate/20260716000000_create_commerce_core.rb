class CreateCommerceCore < ActiveRecord::Migration[7.2]
  def change
    create_table :provinces do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.decimal :gst_rate, precision: 5, scale: 4, null: false, default: 0
      t.decimal :pst_rate, precision: 5, scale: 4, null: false, default: 0
      t.decimal :hst_rate, precision: 5, scale: 4, null: false, default: 0
      t.timestamps
    end
    add_index :provinces, :name, unique: true
    add_index :provinces, :abbreviation, unique: true

    create_table :users do |t|
      t.references :province, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :phone
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :role, null: false, default: "customer"
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :categories, :name, unique: true

    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :brand
      t.string :sku, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :stock_quantity, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :products, :sku, unique: true
    add_index :products, [:active, :category_id]

    create_table :carts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
    add_index :cart_items, [:cart_id, :product_id], unique: true

    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :delivery_method, null: false
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0
      t.decimal :gst_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :pst_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :hst_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :delivery_fee, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.string :recipient_name, null: false
      t.string :phone
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :province_name, null: false
      t.decimal :gst_rate, precision: 5, scale: 4, null: false, default: 0
      t.decimal :pst_rate, precision: 5, scale: 4, null: false, default: 0
      t.decimal :hst_rate, precision: 5, scale: 4, null: false, default: 0
      t.timestamps
    end
    add_index :orders, [:user_id, :created_at]
    add_index :orders, :status

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :product_name, null: false
      t.string :sku, null: false
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :line_total, precision: 10, scale: 2, null: false
      t.timestamps
    end
    add_index :order_items, [:order_id, :product_id]

    create_table :pickup_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, null: true, foreign_key: true
      t.string :pickup_type, null: false
      t.string :status, null: false, default: "requested"
      t.datetime :scheduled_at, null: false
      t.string :address
      t.string :city
      t.string :postal_code
      t.text :notes
      t.timestamps
    end
    add_index :pickup_requests, [:status, :scheduled_at]

    create_table :repair_requests do |t|
      t.references :pickup_request, null: false, foreign_key: true, index: { unique: true }
      t.string :device_type, null: false
      t.string :brand
      t.string :model
      t.text :problem_description, null: false
      t.decimal :estimated_price, precision: 10, scale: 2
      t.string :repair_status, null: false, default: "submitted"
      t.timestamps
    end
  end
end
