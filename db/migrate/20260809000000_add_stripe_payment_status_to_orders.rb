class AddStripePaymentStatusToOrders < ActiveRecord::Migration[7.2]
  def up
    add_column :orders, :stripe_checkout_session_id, :string
    add_column :orders, :stripe_payment_intent_id, :string
    add_column :orders, :paid_at, :datetime
    add_column :orders, :shipped_at, :datetime
    add_index :orders, :stripe_checkout_session_id, unique: true
    add_index :orders, :stripe_payment_intent_id, unique: true

    execute <<~SQL.squish
      UPDATE orders
      SET status = CASE status
        WHEN 'pending' THEN 'new'
        WHEN 'processing' THEN 'paid'
        WHEN 'ready' THEN 'paid'
        WHEN 'completed' THEN 'shipped'
        ELSE status
      END
    SQL

    change_column_default :orders, :status, from: "pending", to: "new"
  end

  def down
    change_column_default :orders, :status, from: "new", to: "pending"
    execute <<~SQL.squish
      UPDATE orders
      SET status = CASE status
        WHEN 'new' THEN 'pending'
        WHEN 'shipped' THEN 'completed'
        ELSE status
      END
    SQL
    remove_index :orders, :stripe_payment_intent_id
    remove_index :orders, :stripe_checkout_session_id
    remove_column :orders, :shipped_at
    remove_column :orders, :paid_at
    remove_column :orders, :stripe_payment_intent_id
    remove_column :orders, :stripe_checkout_session_id
  end
end
