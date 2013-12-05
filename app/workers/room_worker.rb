class RoomWorker
  include Sidekiq::Worker
  extend Forwardable
  
  sidekiq_options retry: false

  attr_accessor :search, :hotel, :finished

  def_delegators :hotel, :ean_hotel_id, :booking_hotel_id, :etb_hotel_id


  def perform(hotel_id, cache_key)
    @hotel = Hotel.find hotel_id
    @search =  Rails.cache.read cache_key
    @finished = false

    unless hotel and search
      Log.warn "Unable to find hotel and search to perform availabilty search for hotel #{hotel_id}, cache key #{cache_key} "
      return
    end

    time = Benchmark.realtime{
      threads = []
      threads << threaded {request_booking_rooms}      if booking_hotel_id
      threads << threaded {request_expedia_rooms}      if ean_hotel_id
      threads << threaded {request_easy_to_book_rooms} if etb_hotel_id
      Log.debug "Waiting for room worker threads to finish"
      threads.each &:join
    }
    Log.info "------ ROOM SEARCH COMPLETED IN #{time} seconds -------- "
    @search.finish
    notify
  end


  def threaded(&block)
    thread = Thread.new do 
      yield
      ActiveRecord::Base.connection.close
    end
    thread
  end

  def request_expedia_rooms
    start :expedia do 
      room_availability_response = Expedia::Search.check_room_availability(ean_hotel_id, search_criteria)
      return unless room_availability_response
      room_availability_response.rooms.map do |room|
        room.commonize(search_criteria)
      end
    end
  end

  def request_booking_rooms
    start :booking do 
      hotel_list_response = Booking::SearchHotel.for_availability(booking_hotel_id, search_criteria)
      return unless hotel_list_response.hotels.length > 0 and booking_hotel = hotel.booking_hotel
      hotel_response = hotel_list_response.hotels.first
      hotel_response.rooms.map do |room|
        room.link = search_criteria.booking_link_detailed(booking_hotel)
        room.commonize(search_criteria)
      end
    end
  end

  def request_easy_to_book_rooms
    start :easy_to_book do 
      hotels_list_response = EasyToBook::SearchHotel.for_availability(etb_hotel_id, search_criteria)
      return unless hotels_list_response.hotels.length > 0
      hotels_list_response.hotels.first.rooms.map do |room|
        room.commonize(search_criteria)
      end
    end
  end

  def start(provider, &block)
    rooms = nil
    time = Benchmark.realtime { rooms = yield }
    rooms.select! {|r| r[:price].to_f >  0}
    Log.info "Realtime availabilty check for #{provider}, finding #{rooms.count} rooms, took #{time}s" 
    return unless rooms.count > 0
    @search.add_rooms(rooms)
    notify
  rescue => msg
    Log.error "Unable to retrieve rooms for provider #{provider}. #{msg}"    
  end

  def search_criteria
    @search.search_criteria
  end

  def channel
    @search.channel
  end

  def notify
    Log.debug "Notifying channel #{channel} of hotel rooms update. Current rooms = #{@search.rooms_results.count}"
    Pusher[channel].trigger('availability_update', { key: @search.cache_key}) 
  end


end