class Feature < ActiveRecord::Base
  attr_accessible :content, :product_id

  belongs_to :product
end
