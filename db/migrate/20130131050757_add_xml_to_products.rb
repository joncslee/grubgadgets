class AddXmlToProducts < ActiveRecord::Migration
  def change
    add_column :products, :xml, :string
  end
end
