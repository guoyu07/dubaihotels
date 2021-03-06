--= SHOULD BE READY TO RUN AND PROCESS DIRECTLY

-- Index: hotels_splendia_hotel_id_idx
DROP INDEX hotels_splendia_hotel_id_idx;
UPDATE hotels SET  splendia_hotel_id = NULL

--select * from splendia_hotels where id =97760
--Add Geography
--ALTER TABLE splendia_hotels ADD COLUMN geog geography(Point,4326);

--Update Geography
UPDATE splendia_hotels SET geog = CAST(ST_SetSRID(ST_Point(longitude, latitude),4326) As geography)

--Index Geography
CREATE INDEX splendia_hotels_geog_idx
  ON splendia_hotels
  USING gist(geog);
 

-- PHASE 1 - MATCH ON NAME / CITY / POSTAL CODE
-- Updated 961
select * from hotels limit 100
UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	LOWER(H.city) = LOWER(SPL.city)
	AND LOWER(H.postal_code) = LOWER(SPL.postal_code)
	AND COALESCE(H.postal_code,'') != ''
	AND LOWER(H.Name) = LOWER(SPL.name);

-- -- PHASE 2 -  MATCH EXACT WITH SAME NAME AND WITHIN 100m
-- 437
UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	LOWER(H.Name) = LOWER(SPL.name)
	AND ST_DWithin(SPL.geog, H.Geog, 100)
	AND H.splendia_hotel_id IS NULL;	

 -- PHASE 3 - MATCH FUZZY NAME ((0.9 correlation) AND WITHIN 500m
-- 374
UPDATE hotels SET splendia_hotel_id =  matched_hotel.splendia_hotel_id
FROM ( 
	SELECT DISTINCT e.id AS splendia_hotel_id, h.id AS hotel_id 
	FROM splendia_hotels e 
	JOIN hotels h ON ST_DWithin(e.geog, h.geog, 500) 
		WHERE h.splendia_hotel_id IS NULL 
		AND similarity(lower(h.name), lower(e.name)) >0.9 ) AS matched_hotel
WHERE matched_hotel.hotel_id = hotels.id and hotels.splendia_hotel_id IS NULL;

 -- PHASE 4 - MATCH FUZZY NAME ((0.9 correlation) AND WITHIN 1km
 -- 58
 UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	H.splendia_hotel_id IS NULL
	AND ST_DWithin(SPL.geog, H.geog, 1000) 
	AND SIMILARITY(H.name, SPL.name) >0.9;
	
	
 -- PHASE 5 - MATCH FUZZY NAME ((0.8 correlation) AND WITHIN 500
 -- 222
UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	H.splendia_hotel_id IS NULL
	AND ST_DWithin(SPL.geog, H.geog, 500) 
	AND SIMILARITY(H.name, SPL.name) >0.8;
	

 -- PHASE 6 - MATCH FUZZY NAME ((0.85 correlation) AND WITHIN 1000
 --  5
UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	H.splendia_hotel_id IS NULL
	AND ST_DWithin(SPL.geog, H.geog, 1000) 
	AND SIMILARITY(H.name, SPL.name) >0.85;
	
-- PHASE 7 - MATCH FUZZY NAME ((0.75 correlation) AND WITHIN 2000
-- 280
UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	H.splendia_hotel_id IS NULL
	AND ST_DWithin(SPL.geog, H.geog, 2000) 
	AND SIMILARITY(H.name, SPL.name) >0.75;

-- PHASE 8 - MATCH FUZZY NAME ((0.75 correlation) AND WITHIN 10000
--  92
UPDATE Public.Hotels AS H
SET splendia_hotel_id = SPL.Id
FROM
	Public.splendia_hotels AS SPL
WHERE
	H.splendia_hotel_id IS NULL
	AND ST_DWithin(SPL.geog, H.geog, 10000) 
	AND SIMILARITY(H.name, SPL.name) >0.8;


DELETE FROM  hotels WHERE hotel_provider = 'splandia'
-- PHASE 8 - INSERT all non-matched EAN hotels
-- 10714
INSERT INTO hotels (
name, 
address, 
city, 
state_province, 
postal_code, 
country_code, 
longitude, 
latitude, 
star_rating, 
check_in_time, 
check_out_time, 
low_rate, 
property_currency, 
geog, 
description, 
splendia_hotel_id, 
splendia_user_rating, 
hotel_provider)
SELECT 
	SPL.name as name, 
	SPL.street  as address, 
	SPL.city as city, 
	SPL.state_province_name as state_province, 
	SPL.postal_code as postal_code, 
	countries.country_code as country_code,
	--lower(countryisocode) as country_code, 
	SPL.longitude, 
	SPL.latitude, 
	CASE substr(stars,2,1) WHEN '' THEN NULL ELSE CAST(substr(stars,2,1) AS DOUBLE PRECISION) END AS star_rating,
	NULL AS check_in,
	NULL AS check_out, 
	CAST(price as double precision) as low_rate, 
	SPL.currency as property_currency, 
	SPL.geog, 
	SPL.description as description, 
	SPL.id as splendia_hotel_id,
	CAST(replace(rating,'%','') AS DOUBLE PRECISION) as splendia_user_rating,
	'splendia' AS hotel_provider
FROM splendia_hotels SPL
JOIN ean_countries countries on countries.country_name = SPL.country
LEFT JOIN hotels h1 ON h1.splendia_hotel_id = SPL.id
WHERE h1.id IS NULL


CREATE INDEX hotels_splendia_hotel_id_idx
  ON hotels
  USING btree
  (splendia_hotel_id);
  
DELETE FROM hotel_images where caption = 'Splendia'
-- 
INSERT INTO hotel_images (hotel_id, caption, url, thumbnail_url,default_image)
SELECT t1.id, 'Splendia', hi.big_image,hi.small_image, false
FROM splendia_hotels hi
JOIN
(SELECT h.id, splendia_hotel_id FROM hotels h 
LEFT JOIN hotel_images i ON h.id = i.hotel_id
WHERE  i.id IS NULL AND  h.splendia_hotel_id IS NOT NULL) as t1
ON t1.splendia_hotel_id = hi.id 


CREATE TABLE splendia_amenities
(
  id serial NOT NULL,
  description text,
  flag integer,
  CONSTRAINT splendia_amenities_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

CREATE TABLE splendia_hotel_amenities
(
  id serial NOT NULL,
  splendia_hotel_id integer,
  amenity character varying(255),
  CONSTRAINT splendia_hotel_amenities_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

TRUNCATE TABLE providers.splendia_hotel_amenities;
INSERT INTO providers.splendia_hotel_amenities (splendia_hotel_id,amenity)
 SELECT id, regexp_split_to_table(other_services, E',') 
 FROM providers.splendia_hotels; 

INSERT INTO providers.splendia_amenities (description)
SELECT DISTINCT amenity from providers.splendia_hotel_amenities;

UPDATE providers.splendia_amenities SET flag = 1 WHERE lower(description) like '%wifi%';
UPDATE providers.splendia_amenities SET flag = 4 WHERE description = 'Activities for children' OR description = 'Babysitting service';
UPDATE providers.splendia_amenities SET flag = 8 WHERE lower(description) like '%parking%';
UPDATE providers.splendia_amenities SET flag = 16 WHERE lower(description) like '%gym%' OR description = 'Fitness Centre';
UPDATE providers.splendia_amenities SET flag = 64 WHERE description = 'Hotel Non-Smoking Throughout' OR description = 'Smoking allowed in public areas';
UPDATE providers.splendia_amenities SET flag =128 WHERE description = 'Pets allowed';
UPDATE providers.splendia_amenities SET flag = 256 WHERE lower(description) like '%pool%' ;
UPDATE providers.splendia_amenities SET flag = 512 WHERE lower(description) like '%restaurant%' and description != 'Restaurant Voucher';
UPDATE providers.splendia_amenities SET flag = 1024 WHERE lower(description) like '%spa%' and description != 'Spa voucher';

UPDATE hotels
SET amenities = T2.bitmask
FROM (
	SELECT T1.splendia_hotel_id, SUM(T1.flag) AS bitmask
	FROM
	(
		SELECT DISTINCT 
			splendia_hotel_id AS splendia_hotel_id, 
			flag  AS flag
		FROM splendia_hotel_amenities spa
		JOIN splendia_amenities sa on sa.description = spa.amenity
		WHERE sa.flag IS NOT NULL
		GROUP BY splendia_hotel_id, flag
		ORDER BY 1
	) AS T1
	GROUP BY T1.splendia_hotel_id
) AS T2
WHERE hotels.splendia_hotel_id = T2.splendia_hotel_id AND hotels.amenities IS NULL

