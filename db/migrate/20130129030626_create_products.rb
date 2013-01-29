class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.text :description
      t.text :amazon_description
      t.string :url

      t.timestamps
    end
  end
end
