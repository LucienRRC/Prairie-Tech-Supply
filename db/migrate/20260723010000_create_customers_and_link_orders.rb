class CreateCustomersAndLinkOrders < ActiveRecord::Migration[7.2]
  def up
    create_table :customers do |t|
      t.references :province, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :address
      t.string :city
      t.string :postal_code
      t.timestamps
    end
    add_index :customers, :email, unique: true

    add_reference :orders, :customer, foreign_key: true
    change_column_null :orders, :user_id, true

    execute <<~SQL
      INSERT INTO customers (
        province_id, first_name, last_name, email, phone, address, city,
        postal_code, created_at, updated_at
      )
      SELECT
        province_id, first_name, last_name, email, phone, address, city,
        postal_code, created_at, updated_at
      FROM users
    SQL

    execute <<~SQL
      UPDATE orders
      SET customer_id = (
        SELECT customers.id
        FROM customers
        INNER JOIN users ON users.email = customers.email
        WHERE users.id = orders.user_id
      )
    SQL

    change_column_null :orders, :customer_id, false
    add_index :orders, [:customer_id, :created_at]
  end

  def down
    remove_index :orders, [:customer_id, :created_at]
    remove_reference :orders, :customer, foreign_key: true
    change_column_null :orders, :user_id, false
    drop_table :customers
  end
end
