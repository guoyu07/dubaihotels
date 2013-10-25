class Booking::HotelRoomSearch

  attr_reader :search_criteria, :response 

  DEFAULT_PARAMS =  {
  }

  CACHE_OPTIONS = {
    expires_in: 4.hours,
    force: true
  }

  def initialize(search_criteria)
    @search_criteria = search_criteria
  end

  def self.by_city_ids(city_ids,search_criteria,params={})
    new(search_criteria).by_city_ids(city_ids, params)
  end

  def by_city_ids(city_ids, options={})        
    params = search_params.merge(options).merge({city_ids: city_ids})  
    Booking::Client.get_hotel_availability(params)
  end

  protected

  def create_response(expedia_response)
    response = Expedia::HotelListResponse.new(expedia_response)
    # Notify Observers
  end

  def search_params
    @params = DEFAULT_PARAMS
    @params.merge!({available_rooms: search_criteria.no_of_rooms, guest_qty: search_criteria.no_of_adults})
    add_children
    add_stars
    add_dates
  end

  def add_children
    return unless search_criteria.children?
    @params.merge!({children_qty: search_criteria.children.count, children_age: search_criteria.children.join(',')}) 
  end

  def add_stars
    return if search_criteria.all_stars? 
    @params.merge!({           
      classes:  [search_criteria.min_stars, search_criteria.max_stars]
    })
  end

  def add_dates
    @params.merge!({ 
      arrival_date:    search_criteria.start_date.to_date.strftime('%Y-%m-%d'),
      departure_date:  search_criteria.end_date.to_date.strftime('%Y-%m-%d')
    })      
  end

  def self.sort_options
    {
      'exact' => 'NO_SORT',
      'popularity' => 'CITY_VALUE',
      'value' => 'OVERALL_VALUE',
      'promo' => 'PROMO', 
      'price' => 'PRICE',
      'price_reverse' => 'PRICE_REVERSE',
      'prive_average' => 'PRIVE_AVERAGE',
      'rating' => 'QUALITY', 
      'rating_reverse' => 'QUALITY_REVERSE',
      'a_z' => 'ALPHA',
      'proximity' => 'PROXIMITY',
      'postal_code' => 'POSTAL_CODE'
    }
  end 
end