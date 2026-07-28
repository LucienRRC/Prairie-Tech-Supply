require "bcrypt"
require "securerandom"

class AddDeviseAuthenticationToCustomers < ActiveRecord::Migration[7.2]
  def up
    add_column :customers, :username, :string
    add_column :customers, :encrypted_password, :string, null: false, default: ""
    add_column :customers, :account_registered, :boolean, null: false, default: false

    select_values("SELECT id FROM customers").each do |customer_id|
      username = "customer_#{customer_id}"
      password_hash = BCrypt::Password.create(SecureRandom.hex(32))

      execute <<~SQL
        UPDATE customers
        SET username = #{connection.quote(username)},
            encrypted_password = #{connection.quote(password_hash.to_s)}
        WHERE id = #{connection.quote(customer_id)}
      SQL
    end

    add_index :customers, :username, unique: true
  end

  def down
    remove_index :customers, :username
    remove_column :customers, :account_registered
    remove_column :customers, :encrypted_password
    remove_column :customers, :username
  end
end
