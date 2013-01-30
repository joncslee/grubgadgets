class Product < ActiveRecord::Base
  attr_accessible :amazon_description, :description, :name, :price, :url, :image_url, :asin

  def self.fetch(asin)

    # method: curate and collect ASIN,
    # query web service using ASIN to
    # obtain attributes and photos
    # http://docs.aws.amazon.com/AWSECommerceService/latest/DG/CHAP_ApiReference.html
    #
    # self.item_lookup for ASIN lookups

    res = Amazon::Ecs.item_lookup(asin, :response_group => 'Medium')
    res
  end

end
