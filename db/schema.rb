# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131014143535) do

  create_table "booking_hotels", :force => true do |t|
    t.string  "district"
    t.integer "nr_rooms"
    t.string  "city"
    t.string  "check_in_to"
    t.string  "check_in_from"
    t.float   "minrate"
    t.string  "url"
    t.integer "review_nr"
    t.string  "address"
    t.float   "commission"
    t.integer "ranking"
    t.integer "city_id"
    t.string  "review_score"
    t.float   "longitude"
    t.float   "latitude"
    t.integer "max_rooms_in_reservation"
    t.integer "max_persons_in_reservation"
    t.string  "name"
    t.integer "hoteltype_id"
    t.boolean "preferred"
    t.string  "country_code"
    t.boolean "class_is_estimated"
    t.boolean "is_closed"
    t.string  "check_out_to"
    t.string  "check_out_from"
    t.string  "zip"
    t.string  "contractchain_id"
    t.float   "maxrate"
    t.integer "classification"
    t.string  "languagecode"
    t.string  "currencycode"
  end

  create_table "cities", :force => true do |t|
    t.string   "country_code"
    t.string   "language_code"
    t.string   "name"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "timezone_name"
    t.string   "timezone_offset"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "countries", :force => true do |t|
    t.string   "area"
    t.string   "country_code"
    t.string   "language_code"
    t.string   "name"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "ean_hotel_attribute_links", :force => true do |t|
    t.integer "ean_hotel_id"
    t.integer "attribute_id"
    t.string  "language_code"
    t.text    "append_text"
  end

  add_index "ean_hotel_attribute_links", ["ean_hotel_id"], :name => "index_ean_hotel_attributes_on_ean_hotel_id"

  create_table "ean_hotel_attributes", :force => true do |t|
    t.integer "attribute_id"
    t.string  "language_code"
    t.string  "description"
    t.string  "attribute_type"
    t.string  "sub_type"
  end

  create_table "ean_hotel_images", :force => true do |t|
    t.integer "ean_hotel_id"
    t.string  "caption"
    t.string  "url"
    t.integer "width"
    t.integer "height"
    t.integer "byte_size"
    t.string  "thumbnail_url"
    t.boolean "default_image"
  end

  add_index "ean_hotel_images", ["ean_hotel_id"], :name => "index_hotel_images_on_ean_hotel_id"

  create_table "ean_hotels", :force => true do |t|
    t.integer "sequence_number"
    t.string  "name"
    t.string  "address1"
    t.string  "address2"
    t.string  "city"
    t.string  "state_province"
    t.string  "postal_code"
    t.string  "country"
    t.float   "latitude"
    t.float   "longitude"
    t.string  "airport_code"
    t.string  "property_category"
    t.string  "property_currency"
    t.float   "star_rating"
    t.integer "confidence"
    t.string  "supplier_type"
    t.string  "location"
    t.string  "chain_code_id"
    t.string  "region_id"
    t.float   "high_rate"
    t.float   "low_rate"
    t.string  "check_in_time"
    t.string  "check_out_time"
  end

  add_index "ean_hotels", ["star_rating", "city"], :name => "index_ean_hotels_on_star_rating_and_city"

  create_table "ean_room_types", :force => true do |t|
    t.integer "ean_hotel_id"
    t.integer "room_type_id"
    t.string  "language_code"
    t.string  "image"
    t.string  "name"
    t.text    "description"
  end

  create_table "hotel_images", :force => true do |t|
    t.integer "hotel_id"
    t.string  "caption"
    t.string  "url"
    t.integer "width"
    t.integer "height"
    t.integer "byte_size"
    t.string  "thumbnail_url"
    t.boolean "default_image"
  end

  add_index "hotel_images", ["hotel_id"], :name => "index_hotel_images_on_hotel_id"

  create_table "hotels", :force => true do |t|
    t.integer "ean_hotel_id"
    t.integer "sequence_number"
    t.string  "name"
    t.string  "address1"
    t.string  "address2"
    t.string  "city"
    t.string  "state_province"
    t.string  "postal_code"
    t.string  "country"
    t.float   "latitude"
    t.float   "longitude"
    t.string  "airport_code"
    t.string  "property_category"
    t.string  "property_currency"
    t.float   "star_rating"
    t.integer "confidence"
    t.string  "supplier_type"
    t.string  "location"
    t.string  "chain_code_id"
    t.string  "region_id"
    t.float   "high_rate"
    t.float   "low_rate"
    t.string  "check_in_time"
    t.string  "check_out_time"
  end

  add_index "hotels", ["ean_hotel_id"], :name => "index_hotels_on_ean_hotel_id", :unique => true
  add_index "hotels", ["star_rating", "city"], :name => "index_hotels_on_star_rating_and_city"

end
