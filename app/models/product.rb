class Product < ActiveRecord::Base
  attr_accessible :amazon_description, :description, :name, :price, :url, :image_url
end
