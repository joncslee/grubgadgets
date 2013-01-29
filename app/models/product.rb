class Product < ActiveRecord::Base
  attr_accessible :amazon_description, :description, :name, :price, :url, :image_url

  def self.fetch(asin)

    # method: curate and collect ASIN,
    # query web service using ASIN to
    # obtain attributes and photos
    # http://docs.aws.amazon.com/AWSECommerceService/latest/DG/CHAP_ApiReference.html
    #
    # self.item_lookup for ASIN lookups

    Amazon::Ecs.options = {
      :associate_tag => 'grubg-20',
      :AWS_access_key_id => 'AKIAJNFWYHUBM55U23AQ',       
      :AWS_secret_key => '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'
    }

    res = Amazon::Ecs.item_search('bake', :search_index => 'Kitchen', :response_group => 'Small', :sort => 'salesrank')

    res.items.each do |item|
      # retrieve string value using XML path
      item_attributes = item.get_element('ItemAttributes')

      author = item_attributes.get('Author') 

      puts "KKKKKK #{item_attributes}"
      break
    end
  end

end
