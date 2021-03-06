module Expedia
  class Room

    attr_reader :data

    def initialize(data)
      @data = data
    end

    def self.find_in(destination)
      Client.hotels_in(destination).map {|h| new h}
    end

    def description
      (data['roomDescription'] || data['roomTypeDescription']) if data
    end

    def chargeable_rates
      rate_infos = data['RateInfos']['RateInfo']
      rate_infos['ConvertedRateInfo'] || rate_infos['ChargeableRateInfo']
    end

    def total
      chargeable_rates['@total'].to_f
    end

    def expedia_id
      data['expediaPropertyId']
    end

    def property_id
      data['propertyId']
    end

    def average
      chargeable_rates['@averageRate']
    end

    def offer_text
      data['RateInfos']['promoDescription']
    end

    def commonize(search_criteria)
      return nil unless expedia_id || property_id
      {
        provider: :expedia,
        provider_id: expedia_id || property_id,
        description: description,
        price: avg_price(total, search_criteria.total_nights),
        #link: search_criteria.expedia_link(expedia_id || property_id),
        offer: offer_text
      }
    end

    def commonize_to_hotels_dot_com(search_criteria, hotel_id)
      {
        provider: :hotels,
        provider_id: property_id,

        description: description,
        price: avg_price(total, search_criteria.total_nights),
        #link: search_criteria.hotels_link(hotel_id),
        offer: offer_text
      }
    end    
    
    def avg_price(price, nights)
      price / nights
    end


    private 
    def method_missing(method, *args, &block)
      @data[method.to_s]
    end

  end

end
