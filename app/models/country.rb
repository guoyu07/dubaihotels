class Country < ActiveRecord::Base
  attr_accessible :area, :country_code, :language_code, :name

  def self.from_booking(json)
    Country.new area: json['area'], 
    country_code: json['countrycode'], 
    language_code: json['languagecode'],  
    name: json['name']    
  end

  def self.seed_from_booking
    offset, countries = 0, []

    while booking_countries = Booking::Seed.countries(offset)
      countries += booking_countries
      offset += 1000
    end

    transaction do 
      delete_all
      import countries
    end
  end  
end
