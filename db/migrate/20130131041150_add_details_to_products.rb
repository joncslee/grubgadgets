class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :list_price, :float
    add_column :products, :brand, :string
    add_column :products, :color, :string
    add_column :products, :size, :string
    add_column :products, :warranty, :string
  end
end
