class HotelsHash

  attr_reader :hotels, :providers, :location


  def initialize(hotels_list, provider_hotels_list, location)
    @location = location
    hash_hotels hotels_list
    hash_provider_hotels provider_hotels_list
  end


  def self.select_cols
    'id, star_rating, amenities, longitude, latitude, user_rating, provider_hotel_ranking, provider_hotel_count, slug'
  end

  def self.by_location_slug(slug)
    by_location Location.find_by_slug(slug)
  end

  def self.by_location(location)
    hotels = Hotel.by_location(location).select(select_cols)
    provider_hotels_list = ProviderHotel.for_comparison(hotels.map(&:id))
    new hotels, provider_hotels_list, location
  end

  def [](name)
    providers[name]
  end

  def hotels_with_deals(inc_this_slug)
    hotel_comparisons.select {|h| h.has_a_deal? or h.slug == inc_this_slug}
  end

  def hotel_comparisons
    hotels.values
  end

  def provider_ids_for(provider)
    results = providers[provider.to_sym]
    results ? results.keys : []
  end

  def hotels_ids_for(provider)
    providers[provider.to_sym].values
  end

  def find_hotel_for(provider, id)
    hotels[providers[provider][id]]
  end

  protected

  def hash_hotels(hotels_list)
    Log.debug "HotelsHash::hash_hotels - BEGIN"
    @hotels = {}
    hotels_list.each do |hotel| 
      hotel_comparison = HotelComparisons.new(hotel)
      hotel_comparison.distance_from_location = hotel_comparison.distance_from(location) 
      hotels[hotel.id] = hotel_comparison
    end

    hotels_list = nil
    Log.debug "HotelsHash::hash_hotels - END"
    hotels
  end

  def hash_provider_hotels(provider_hotels_list)
    Log.debug "HotelsHash::hash_provider_hotels - BEGIN"

    @providers = {}

    provider_hotels_list.each do |provider_hotel|
      provider = provider_hotel.provider.to_sym
      hotel_id = provider_hotel.hotel_id
      providers[provider] ||= {}      
      providers[provider][provider_hotel.provider_id] = hotel_id
      hotels[hotel_id].provider_init(provider_hotel)
    end
    Log.debug "HotelsHash::hash_provider_hotels - END"

    provider_hotels_list = nil
  end

  def map_hotel(hotel_result)
    Hotel.new(hotel_result)
  end

end