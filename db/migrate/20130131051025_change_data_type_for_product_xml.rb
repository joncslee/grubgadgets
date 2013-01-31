class ChangeDataTypeForProductXml < ActiveRecord::Migration
  def self.up
    change_table :products do |t|
      t.change :xml, :text
    end
  end

  def self.down
    change_table :products do |t|
      t.change :xml, :string
    end
  end
end
