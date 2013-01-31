class CreateFeatures < ActiveRecord::Migration
  def change
    create_table :features do |t|
      t.text :content
      t.integer :product_id

      t.timestamps
    end
  end
end
