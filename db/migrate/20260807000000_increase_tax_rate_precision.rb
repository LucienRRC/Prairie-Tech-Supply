class IncreaseTaxRatePrecision < ActiveRecord::Migration[7.2]
  def change
    [:gst_rate, :pst_rate, :hst_rate].each do |column|
      change_column :provinces, column, :decimal,
        precision: 6, scale: 5, null: false, default: 0
      change_column :orders, column, :decimal,
        precision: 6, scale: 5, null: false, default: 0
    end

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE provinces
          SET pst_rate = 0.09975
          WHERE abbreviation = 'QC'
        SQL
      end
    end
  end
end
