class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find_by_id(params[:id])

    # fetch raw data from Amazon webservice by ASIN
    data = Product.fetch(@product.asin).first_item

    # convert response to nokogiri object
    doc = Nokogiri.XML(data.to_s) do |config|
      config.default_xml.noblanks
    end

    item_attributes = doc.xpath('/Item/ItemAttributes')
    editorial_reviews = doc.xpath('/Item/EditorialReviews')
    offers = doc.xpath('/Item/Offers')

    features = []
    item_attributes.xpath('Feature').each do |feature|
      features << feature.text
    end

    # use xpath selectors to extract relevant data 
    # into usable hash
    @product_data = {
      :list_price => item_attributes.xpath('ListPrice/Amount').text,
      :price => offers.xpath('Offer/OfferListing/Price/Amount').text,
      :brand => item_attributes.xpath('Brand').text,
      :color => item_attributes.xpath('Color').text,
      :size => item_attributes.xpath('Size').text,
      :warranty => item_attributes.xpath('Warranty').text,
      # figure out how to extract ONLY the product description (not amazon description)
      :description => editorial_reviews.xpath('EditorialReview[1]/Content').text,
      :features => features,
      :image_url => doc.xpath('/Item/LargeImage/URL').text
    }

  end


end
