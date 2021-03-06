class Product < ActiveRecord::Base
  attr_accessible :amazon_description, :description, :name, :price, :list_price, :url, :image_url, :asin, :photo, :brand, :color, :size, :warranty, :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :xml
  
  has_attached_file :photo

  has_many :features

  before_save :fetch_details_from_amazon
  after_save :create_features
  
  def fetch_details_from_amazon
    data = Product.fetch(self.asin).first_item

    # convert response to nokogiri object
    doc = Nokogiri.XML(data.to_s) do |config|
      config.default_xml.noblanks
    end

    self.xml = doc.to_s

    item_attributes = doc.xpath('/Item/ItemAttributes')
    editorial_reviews = doc.xpath('/Item/EditorialReviews')
    offers = doc.xpath('/Item/Offers')


    if item_attributes.present?
      self.list_price = item_attributes.xpath('ListPrice/Amount').text.to_f / 100
      self.brand = item_attributes.xpath('Brand').text
      self.color = item_attributes.xpath('Color').text
      self.size = item_attributes.xpath('Size').text
      self.warranty = item_attributes.xpath('Warranty').text
    end

    self.price = offers.xpath('Offer/OfferListing/Price/Amount').text.to_f / 100 if offers
    self.description = editorial_reviews.xpath('EditorialReview[1]/Content').text if editorial_reviews
    self.image_url = doc.xpath('/Item/LargeImage/URL').text

    require 'open-uri'
    self.photo = open(self.image_url) if self.image_url

  end

  def create_features
    if self.features.blank?
      doc = Nokogiri.XML(self.xml.to_s)
      item_attributes = doc.xpath('/Item/ItemAttributes')
      item_attributes.xpath('Feature').each do |feature|
        self.features.create(:content => feature.text)
      end
    end
  end

  def self.fetch(asin)

    # method: curate and collect ASIN,
    # query web service using ASIN to
    # obtain attributes and photos
    # http://docs.aws.amazon.com/AWSECommerceService/latest/DG/CHAP_ApiReference.html
    #
    # self.item_lookup for ASIN lookups

    res = Amazon::Ecs.item_lookup(asin, :response_group => 'Large')
    res
  end

#   <?xml version="1.0"?>
#   <Item>
#     <ASIN>B00004SPZV</ASIN>
#     <ParentASIN>B009K3ZTSQ</ParentASIN>
#     <DetailPageURL>http://www.amazon.com/Misto-Gourmet-Sprayer-Brushed-Aluminum/dp/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D165953%26creativeASIN%3DB00004SPZV</DetailPageURL>
#     <ItemLinks>
#       <ItemLink>
#         <Description>Technical Details</Description>
#         <URL>http://www.amazon.com/Misto-Gourmet-Sprayer-Brushed-Aluminum/dp/tech-data/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#       <ItemLink>
#         <Description>Add To Baby Registry</Description>
#         <URL>http://www.amazon.com/gp/registry/baby/add-item.html%3Fasin.0%3DB00004SPZV%26SubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#       <ItemLink>
#         <Description>Add To Wedding Registry</Description>
#         <URL>http://www.amazon.com/gp/registry/wedding/add-item.html%3Fasin.0%3DB00004SPZV%26SubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#       <ItemLink>
#         <Description>Add To Wishlist</Description>
#         <URL>http://www.amazon.com/gp/registry/wishlist/add-item.html%3Fasin.0%3DB00004SPZV%26SubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#       <ItemLink>
#         <Description>Tell A Friend</Description>
#         <URL>http://www.amazon.com/gp/pdp/taf/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#       <ItemLink>
#         <Description>All Customer Reviews</Description>
#         <URL>http://www.amazon.com/review/product/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#       <ItemLink>
#         <Description>All Offers</Description>
#         <URL>http://www.amazon.com/gp/offer-listing/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</URL>
#       </ItemLink>
#     </ItemLinks>
#     <SalesRank>20</SalesRank>
#     <SmallImage>
#       <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL75_.jpg</URL>
#       <Height Units="pixels">75</Height>
#       <Width Units="pixels">21</Width>
#     </SmallImage>
#     <MediumImage>
#       <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL160_.jpg</URL>
#       <Height Units="pixels">160</Height>
#       <Width Units="pixels">46</Width>
#     </MediumImage>
#     <LargeImage>
#       <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL.jpg</URL>
#       <Height Units="pixels">500</Height>
#       <Width Units="pixels">143</Width>
#     </LargeImage>
#     <ImageSets>
#       <ImageSet Category="primary">
#         <SwatchImage>
#           <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL30_.jpg</URL>
#           <Height Units="pixels">30</Height>
#           <Width Units="pixels">9</Width>
#         </SwatchImage>
#         <SmallImage>
#           <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL75_.jpg</URL>
#           <Height Units="pixels">75</Height>
#           <Width Units="pixels">21</Width>
#         </SmallImage>
#         <ThumbnailImage>
#           <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL75_.jpg</URL>
#           <Height Units="pixels">75</Height>
#           <Width Units="pixels">21</Width>
#         </ThumbnailImage>
#         <TinyImage>
#           <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL110_.jpg</URL>
#           <Height Units="pixels">110</Height>
#           <Width Units="pixels">31</Width>
#         </TinyImage>
#         <MediumImage>
#           <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL._SL160_.jpg</URL>
#           <Height Units="pixels">160</Height>
#           <Width Units="pixels">46</Width>
#         </MediumImage>
#         <LargeImage>
#           <URL>http://ecx.images-amazon.com/images/I/31D6GBYVAYL.jpg</URL>
#           <Height Units="pixels">500</Height>
#           <Width Units="pixels">143</Width>
#         </LargeImage>
#       </ImageSet>
#     </ImageSets>
#     <ItemAttributes>
#       <Binding>Kitchen</Binding>
#       <Brand>Misto</Brand>
#       <CatalogNumberList>
#         <CatalogNumberListElement>M100S</CatalogNumberListElement>
#       </CatalogNumberList>
#       <Color>Brushed Aluminum</Color>
#       <EAN>0639108008894</EAN>
#       <EANList>
#         <EANListElement>0639108008894</EANListElement>
#         <EANListElement>0024131114962</EANListElement>
#         <EANListElement>0639108008887</EANListElement>
#       </EANList>
#       <Feature>To clean, fill with hot water and a drop of mild detergent, and spray.</Feature>
#       <Feature>7-5/8-Inch high by 1-7/8-inch in diameter</Feature>
#       <Feature>Satin-finish aluminum</Feature>
#       <Feature>Spread olive oil on focaccia or spray muffin pans</Feature>
#       <Feature>Pumps up to spray any vegetable oil</Feature>
#       <ItemDimensions>
#         <Height Units="hundredths-inches">750</Height>
#         <Length Units="hundredths-inches">0</Length>
#         <Weight Units="hundredths-pounds">30</Weight>
#         <Width Units="hundredths-inches">200</Width>
#       </ItemDimensions>
#       <Label>Misto International LLC</Label>
#       <LegalDisclaimer>Misto</LegalDisclaimer>
#       <ListPrice>
#         <Amount>1599</Amount>
#         <CurrencyCode>USD</CurrencyCode>
#         <FormattedPrice>$15.99</FormattedPrice>
#       </ListPrice>
#       <Manufacturer>Misto International LLC</Manufacturer>
#       <Model>M100S</Model>
#       <MPN>M100S</MPN>
#       <PackageDimensions>
#         <Height Units="hundredths-inches">280</Height>
#         <Length Units="hundredths-inches">970</Length>
#         <Weight Units="hundredths-pounds">35</Weight>
#         <Width Units="hundredths-inches">320</Width>
#       </PackageDimensions>
#       <PackageQuantity>1</PackageQuantity>
#       <PartNumber>M100S</PartNumber>
#       <ProductGroup>Kitchen</ProductGroup>
#       <ProductTypeName>KITCHEN</ProductTypeName>
#       <Publisher>Misto International LLC</Publisher>
#       <Size>1 Pack</Size>
#       <SKU>lbw-024131114962</SKU>
#       <Studio>Misto International LLC</Studio>
#       <Title>Misto Gourmet Olive Oil Sprayer, Brushed Aluminum</Title>
#       <UPC>639108008894</UPC>
#       <UPCList>
#         <UPCListElement>639108008894</UPCListElement>
#         <UPCListElement>024131114962</UPCListElement>
#         <UPCListElement>639108008887</UPCListElement>
#       </UPCList>
#       <Warranty>1 year</Warranty>
#     </ItemAttributes>
#     <OfferSummary>
#       <LowestNewPrice>
#         <Amount>497</Amount>
#         <CurrencyCode>USD</CurrencyCode>
#         <FormattedPrice>$4.97</FormattedPrice>
#       </LowestNewPrice>
#       <LowestUsedPrice>
#         <Amount>499</Amount>
#         <CurrencyCode>USD</CurrencyCode>
#         <FormattedPrice>$4.99</FormattedPrice>
#       </LowestUsedPrice>
#       <TotalNew>22</TotalNew>
#       <TotalUsed>2</TotalUsed>
#       <TotalCollectible>0</TotalCollectible>
#       <TotalRefurbished>0</TotalRefurbished>
#     </OfferSummary>
#     <Offers>
#       <TotalOffers>1</TotalOffers>
#       <TotalOfferPages>1</TotalOfferPages>
#       <MoreOffersUrl>http://www.amazon.com/gp/offer-listing/B00004SPZV%3FSubscriptionId%3DAKIAJNFWYHUBM55U23AQ%26tag%3Dgrubg-20%26linkCode%3Dxm2%26camp%3D2025%26creative%3D386001%26creativeASIN%3DB00004SPZV</MoreOffersUrl>
#       <Offer>
#         <OfferAttributes>
#           <Condition>New</Condition>
#         </OfferAttributes>
#         <OfferListing>
#           <OfferListingId>iYj9z1d4jR5xoZWas4mlScu3zPCpYbUdNv%2F9E3gYRJKK9Jvj1jUU%2BNewVEpRJy5KDwZlfe4XJOC1fkZVvcOBmdmonbZ7tv9%2FkDJEQb5I0jk%3D</OfferListingId>
#           <Price>
#             <Amount>999</Amount>
#             <CurrencyCode>USD</CurrencyCode>
#             <FormattedPrice>$9.99</FormattedPrice>
#           </Price>
#           <AmountSaved>
#             <Amount>600</Amount>
#             <CurrencyCode>USD</CurrencyCode>
#             <FormattedPrice>$6.00</FormattedPrice>
#           </AmountSaved>
#           <PercentageSaved>38</PercentageSaved>
#           <Availability>Usually ships in 24 hours</Availability>
#           <AvailabilityAttributes>
#             <AvailabilityType>now</AvailabilityType>
#             <MinimumHours>0</MinimumHours>
#             <MaximumHours>0</MaximumHours>
#           </AvailabilityAttributes>
#           <IsEligibleForSuperSaverShipping>1</IsEligibleForSuperSaverShipping>
#         </OfferListing>
#       </Offer>
#     </Offers>
#     <CustomerReviews>
#       <IFrameURL>http://www.amazon.com/reviews/iframe?akid=AKIAJNFWYHUBM55U23AQ&amp;alinkCode=xm2&amp;asin=B00004SPZV&amp;atag=grubg-20&amp;exp=2013-02-01T03%3A34%3A00Z&amp;v=2&amp;sig=RWoABvbesG%2BxWdu58hYvO094krW8ZzAI3ifP5XoiIU4%3D</IFrameURL>
#       <HasReviews>true</HasReviews>
#     </CustomerReviews>
#     <EditorialReviews>
#       <EditorialReview>
#         <Source>Product Description</Source>
#         <Content>The Misto Oil Bottle Sprayer is now available in vibrant colors to match your kitchen. The sprayer is designed with the health-conscious cook in mind and is perfect for low fat/high flavor cooking, grilling, saut&#xE9;ing, roasting and basting. Misto is ideal for spraying olive oil on salads, pasta, veggies, breads, pizza, chicken, beef and fish. It even works as a plant mister when filled with water. Buy one for your favorite oils, vinegars, lemon or lime juice and more. Refill and reuse again and again!</Content>
#         <IsLinkSuppressed>0</IsLinkSuppressed>
#       </EditorialReview>
#       <EditorialReview>
#         <Source>Amazon.com</Source>
#         <Content>For spreading olive oil evenly on bruschetta, focaccia, and grilled or roasted vegetables, and for spraying muffin and cake pans with vegetable oil, this dispenser is a nifty tool. A plastic cap underneath the sprayer's top twists off so the sprayer can be half-filled (1/3 cup) with oil. Inside the top is a plastic tube that fits over the spray nozzle. Push the top up and down to pump air pressure into the canister. Then spray for 10 seconds and pump up again. It's simple, ingenious, and practical. With its cap on, the sprayer stands just 7-5/8 inches high, so it tucks away easily on any countertop. Made of satin-finish aluminum with a black-band accent, it's sleek as well as utilitarian. &lt;I&gt;--Fred Brack&lt;/I&gt; </Content>
#         <IsLinkSuppressed>0</IsLinkSuppressed>
#       </EditorialReview>
#     </EditorialReviews>
#     <SimilarProducts>
#       <SimilarProduct>
#         <ASIN>B008FR8A5C</ASIN>
#         <Title>Misto Oil Sprayer - Teal</Title>
#       </SimilarProduct>
#       <SimilarProduct>
#         <ASIN>B00006IUWA</ASIN>
#         <Title>Presto 04820 PopLite Hot Air Popper, White</Title>
#       </SimilarProduct>
#       <SimilarProduct>
#         <ASIN>B000N5WJVK</ASIN>
#         <Title>iTouchless Automatic Stainless Steel Pepper Mill and Salt Grinder (2 Pack)</Title>
#       </SimilarProduct>
#       <SimilarProduct>
#         <ASIN>B00629JRL6</ASIN>
#         <Title>Misto Gourmet Olive Oil Sprayer, Tomato</Title>
#       </SimilarProduct>
#       <SimilarProduct>
#         <ASIN>B000F8JUJY</ASIN>
#         <Title>Amco Rub Away Bar</Title>
#       </SimilarProduct>
#     </SimilarProducts>
#     <Accessories>
#       <Accessory>
#         <ASIN>B00004OCKR</ASIN>
#         <Title>OXO Good Grips  Salad Spinner</Title>
#       </Accessory>
#     </Accessories>
#     <BrowseNodes>
#       <BrowseNode>
#         <BrowseNodeId>678513011</BrowseNodeId>
#         <Name>Oil Sprayers</Name>
#         <Ancestors>
#           <BrowseNode>
#             <BrowseNodeId>289789</BrowseNodeId>
#             <Name>Oil Sprayers &amp; Dispensers</Name>
#             <Ancestors>
#               <BrowseNode>
#                 <BrowseNodeId>289754</BrowseNodeId>
#                 <Name>Kitchen Utensils &amp; Gadgets</Name>
#                 <Ancestors>
#                   <BrowseNode>
#                     <BrowseNodeId>284507</BrowseNodeId>
#                     <Name>Kitchen &amp; Dining</Name>
#                     <Ancestors>
#                       <BrowseNode>
#                         <BrowseNodeId>1063498</BrowseNodeId>
#                         <Name>Categories</Name>
#                         <IsCategoryRoot>1</IsCategoryRoot>
#                         <Ancestors>
#                           <BrowseNode>
#                             <BrowseNodeId>1055398</BrowseNodeId>
#                             <Name>Home &amp; Kitchen</Name>
#                           </BrowseNode>
#                         </Ancestors>
#                       </BrowseNode>
#                     </Ancestors>
#                   </BrowseNode>
#                 </Ancestors>
#               </BrowseNode>
#             </Ancestors>
#           </BrowseNode>
#         </Ancestors>
#       </BrowseNode>
#       <BrowseNode>
#         <BrowseNodeId>13900811</BrowseNodeId>
#         <Name>Home &amp; Kitchen Features</Name>
#         <Children>
#           <BrowseNode>
#             <BrowseNodeId>51551011</BrowseNodeId>
#             <Name>Featured Categories</Name>
#           </BrowseNode>
#         </Children>
#         <Ancestors>
#           <BrowseNode>
#             <BrowseNodeId>1055398</BrowseNodeId>
#             <Name>Home &amp; Kitchen</Name>
#           </BrowseNode>
#         </Ancestors>
#       </BrowseNode>
#       <BrowseNode>
#         <BrowseNodeId>13900821</BrowseNodeId>
#         <Name>Kitchen &amp; Dining Features</Name>
#         <Children>
#           <BrowseNode>
#             <BrowseNodeId>51552011</BrowseNodeId>
#             <Name>Featured Categories</Name>
#           </BrowseNode>
#         </Children>
#         <Ancestors>
#           <BrowseNode>
#             <BrowseNodeId>1055398</BrowseNodeId>
#             <Name>Home &amp; Kitchen</Name>
#           </BrowseNode>
#         </Ancestors>
#       </BrowseNode>
#     </BrowseNodes>
#   </Item>

end
