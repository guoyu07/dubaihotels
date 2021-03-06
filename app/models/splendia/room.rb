module Splendia
  class Room

    attr_reader :xml

    def initialize(xml)
      @xml = xml
    end

    def self.from_hotel_response(xml_response)
      xml_response.xpath('rooms/room').map {|room| new room}
    end

    def description
      @description ||= value('roomname')
    end

    def daily_price
      @daily_price ||= value('fullratewithtaxes').to_f
    end

    def price      
      @price ||= value('totalfullratewithtaxes').to_f
    end

    def breakfast?
      value('ratebreakfastincluded').to_i === 1
    end

    def cancellation?
      value('ratefreecancellable').to_i === 1
    end


    def commonize(search_criteria)
      {
        provider: :splendia,
        description: description,
        price: avg_price(search_criteria.total_nights),
        #link: link,
        breakfast: breakfast?,
        cancellation: cancellation?
      }
    end


    def avg_price(nights)
      price / nights
    end

    def value(path)
      el = xml.at_xpath(path)
      el.text if el
    end

  end

end
