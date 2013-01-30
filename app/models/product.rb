class Product < ActiveRecord::Base
  attr_accessible :amazon_description, :description, :name, :price, :url, :image_url, :asin

  before_save :fetch_details_from_amazon
  
  def fetch_details_from_amazon
    data = fetch(asin).first_item

    # convert response to nokogiri object
    doc = Nokogiri.XML(data.to_s) do |config|
      config.default_xml.noblanks
    end

    item_attributes = doc.xpath('/Item/ItemAttributes')
    editorial_reviews = doc.xpath('/Item/EditorialReviews')

    features = []
    item_attributes.xpath('Feature').each do |feature|
      features << feature.text
    end

    # use xpath selectors to extract relevant data 
    # into usable hash
    @product_data = {
      :list_price => item_attributes.xpath('ListPrice/FormattedPrice').text,
      :brand => item_attributes.xpath('Brand').text,
      :color => item_attributes.xpath('Color').text,
      :size => item_attributes.xpath('Size').text,
      :warranty => item_attributes.xpath('Warranty').text,
      # figure out how to extract ONLY the product description (not amazon description)
      :description => editorial_reviews.xpath('EditorialReview[1]/Content').text,
      :features => features
    }

  end

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

# xml example for response group medium
# <?xml version="1.0"?>
# <Item>
#   <ASIN>B00004SPZV</ASIN>
#   <ParentASIN>B009K3ZTSQ</ParentASIN>
#   <DetailPageURL>http://www.amazon.com/Misto-Gourmet-Sprayer-Brushed-Aluminum/dp/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D165953%26creativeASIN%3DB00004SPZV</DetailPageURL>
#   <ItemLinks>
#     <ItemLink>
#       <Description>Technical Details</Description>
#       <URL>http://www.amazon.com/Misto-Gourmet-Sprayer-Brushed-Aluminum/dp/tech-data/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#     <ItemLink>
#       <Description>Add To Baby Registry</Description>
#       <URL>http://www.amazon.com/gp/registry/baby/add-item.html%3Fasin.0%3DB00004SPZV%26SubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#     <ItemLink>
#       <Description>Add To Wedding Registry</Description>
#       <URL>http://www.amazon.com/gp/registry/wedding/add-item.html%3Fasin.0%3DB00004SPZV%26SubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#     <ItemLink>
#       <Description>Add To Wishlist</Description>
#       <URL>http://www.amazon.com/gp/registry/wishlist/add-item.html%3Fasin.0%3DB00004SPZV%26SubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#     <ItemLink>
#       <Description>Tell A Friend</Description>
#       <URL>http://www.amazon.com/gp/pdp/taf/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#     <ItemLink>
#       <Description>All Customer Reviews</Description>
#       <URL>http://www.amazon.com/review/product/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#     <ItemLink>
#       <Description>All Offers</Description>
#       <URL>http://www.amazon.com/gp/offer-listing/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#     </ItemLink>
#   </ItemLinks>
#   <SalesRank>16</SalesRank>
#   <SmallImage>
#     <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL75_.jpg</URL>
#     <Height Units="pixels">75</Height>
#     <Width Units="pixels">21</Width>
#   </SmallImage>
#   <MediumImage>
#     <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL160_.jpg</URL>
#     <Height Units="pixels">160</Height>
#     <Width Units="pixels">46</Width>
#   </MediumImage>
#   <LargeImage>
#     <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL.jpg</URL>
#     <Height Units="pixels">500</Height>
#     <Width Units="pixels">143</Width>
#   </LargeImage>
#   <ImageSets>
#     <ImageSet Category="primary">
#       <SwatchImage>
#         <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL30_.jpg</URL>
#         <Height Units="pixels">30</Height>
#         <Width Units="pixels">9</Width>
#       </SwatchImage>
#       <SmallImage>
#         <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL75_.jpg</URL>
#         <Height Units="pixels">75</Height>
#         <Width Units="pixels">21</Width>
#       </SmallImage>
#       <ThumbnailImage>
#         <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL75_.jpg</URL>
#         <Height Units="pixels">75</Height>
#         <Width Units="pixels">21</Width>
#       </ThumbnailImage>
#       <TinyImage>
#         <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL110_.jpg</URL>
#         <Height Units="pixels">110</Height>
#         <Width Units="pixels">31</Width>
#       </TinyImage>
#       <MediumImage>
#         <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL160_.jpg</URL>
#         <Height Units="pixels">160</Height>
#         <Width Units="pixels">46</Width>
#       </MediumImage>
#       <LargeImage>
#         <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL.jpg</URL>
#         <Height Units="pixels">500</Height>
#         <Width Units="pixels">143</Width>
#       </LargeImage>
#     </ImageSet>
#   </ImageSets>
#   <ItemAttributes>
#     <Binding>Kitchen</Binding>
#     <Brand>Misto</Brand>
#     <CatalogNumberList>
#       <CatalogNumberListElement>M100S</CatalogNumberListElement>
#     </CatalogNumberList>
#     <Color>Brushed Aluminum</Color>
#     <EAN>0639108008894</EAN>
#     <EANList>
#       <EANListElement>0639108008894</EANListElement>
#       <EANListElement>0024131114962</EANListElement>
#       <EANListElement>0639108008887</EANListElement>
#     </EANList>
#     <Feature>To clean, fill with hot water and a drop of mild detergent, and spray.</Feature>
#     <Feature>7-5/8-Inch high by 1-7/8-inch in diameter</Feature>
#     <Feature>Satin-finish aluminum</Feature>
#     <Feature>Spread olive oil on focaccia or spray muffin pans</Feature>
#     <Feature>Pumps up to spray any vegetable oil</Feature>
#     <ItemDimensions>
#       <Height Units="hundredths-inches">750</Height>
#       <Length Units="hundredths-inches">0</Length>
#       <Weight Units="hundredths-pounds">30</Weight>
#       <Width Units="hundredths-inches">200</Width>
#     </ItemDimensions>
#     <Label>Misto International LLC</Label>
#     <LegalDisclaimer>Misto</LegalDisclaimer>
#     <ListPrice>
#       <Amount>1599</Amount>
#       <CurrencyCode>USD</CurrencyCode>
#       <FormattedPrice>$15.99</FormattedPrice>
#     </ListPrice>
#     <Manufacturer>Misto International LLC</Manufacturer>
#     <Model>M100S</Model>
#     <MPN>M100S</MPN>
#     <PackageDimensions>
#       <Height Units="hundredths-inches">280</Height>
#       <Length Units="hundredths-inches">970</Length>
#       <Weight Units="hundredths-pounds">35</Weight>
#       <Width Units="hundredths-inches">320</Width>
#     </PackageDimensions>
#     <PackageQuantity>1</PackageQuantity>
#     <PartNumber>M100S</PartNumber>
#     <ProductGroup>Kitchen</ProductGroup>
#     <ProductTypeName>KITCHEN</ProductTypeName>
#     <Publisher>Misto International LLC</Publisher>
#     <Size>1 Pack</Size>
#     <SKU>lbw-024131114962</SKU>
#     <Studio>Misto International LLC</Studio>
#     <Title>Misto Gourmet Olive Oil Sprayer, Brushed Aluminum</Title>
#     <UPC>639108008894</UPC>
#     <UPCList>
#       <UPCListElement>639108008894</UPCListElement>
#       <UPCListElement>024131114962</UPCListElement>
#       <UPCListElement>639108008887</UPCListElement>
#     </UPCList>
#     <Warranty>1 year</Warranty>
#   </ItemAttributes>
#   <OfferSummary>
#     <LowestNewPrice>
#       <Amount>799</Amount>
#       <CurrencyCode>USD</CurrencyCode>
#       <FormattedPrice>$7.99</FormattedPrice>
#     </LowestNewPrice>
#     <LowestUsedPrice>
#       <Amount>499</Amount>
#       <CurrencyCode>USD</CurrencyCode>
#       <FormattedPrice>$4.99</FormattedPrice>
#     </LowestUsedPrice>
#     <TotalNew>19</TotalNew>
#     <TotalUsed>2</TotalUsed>
#     <TotalCollectible>0</TotalCollectible>
#     <TotalRefurbished>0</TotalRefurbished>
#   </OfferSummary>
#   <EditorialReviews>
#     <EditorialReview>
#       <Source>Product Description</Source>
#       <Content>The Misto Oil Bottle Sprayer is now available in vibrant colors to match your kitchen. The sprayer is designed with the health-conscious cook in mind and is perfect for low fat/high flavor cooking, grilling, saut&#xE9;ing, roasting and basting. Misto is ideal for spraying olive oil on salads, pasta, veggies, breads, pizza, chicken, beef and fish. It even works as a plant mister when filled with water. Buy one for your favorite oils, vinegars, lemon or lime juice and more. Refill and reuse again and again!</Content>
#       <IsLinkSuppressed>0</IsLinkSuppressed>
#     </EditorialReview>
#     <EditorialReview>
#       <Source>Amazon.com</Source>
#       <Content>For spreading olive oil evenly on bruschetta, focaccia, and grilled or roasted vegetables, and for spraying muffin and cake pans with vegetable oil, this dispenser is a nifty tool. A plastic cap underneath the sprayer's top twists off so the sprayer can be half-filled (1/3 cup) with oil. Inside the top is a plastic tube that fits over the spray nozzle. Push the top up and down to pump air pressure into the canister. Then spray for 10 seconds and pump up again. It's simple, ingenious, and practical. With its cap on, the sprayer stands just 7-5/8 inches high, so it tucks away easily on any countertop. Made of satin-finish aluminum with a black-band accent, it's sleek as well as utilitarian. &lt;I&gt;--Fred Brack&lt;/I&gt; </Content>
#       <IsLinkSuppressed>0</IsLinkSuppressed>
#     </EditorialReview>
#   </EditorialReviews>
# </Item>

end
