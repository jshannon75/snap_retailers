#This script adds county, tract, PUMA, MSA, and city IDs to the SNAP store data.
library(tidyverse)
library(sf)

#Read in data ####
stores_raw<-read_csv("data/snap_retailers_usda.csv")
stores_raw_sf<-st_as_sf(stores_raw,coords=c("X","Y"),crs=4326)
tracts<-st_read("C:/Users/jshannon/Dropbox/Jschool/GIS data/Census/US_tracts/US_tract_2016_msa.shp") %>%
  select(STATEFP,COUNTYFP,GEOID,GISJOIN,msa_fips,msa_name) %>%
  mutate("cty_fips"=paste(STATEFP,COUNTYFP,sep="")) %>%
  rename("st_fips"=STATEFP,
         "tract_fips"=GEOID,
         "gisjn_tct"=GISJOIN) %>%
  st_transform(4326)
pumas16<-st_read("C:/Users/jshannon/Dropbox/Jschool/GIS data/Census/PUMAs/US_puma_2016.shp") %>%
  st_transform(4326) %>%
  select(GEOID10,GISJOIN) %>%
  rename("puma_fips"=GEOID10,"gisjn_puma"=GISJOIN)
places16<-st_read("C:/Users/jshannon/Dropbox/Jschool/GIS data/Census/Census places/US_place_2016.shp") %>%
  st_transform(4326) %>%
  select("GEOID","NAMELSAD","GISJOIN") %>%
  rename("place_fips"=GEOID,
         "place_name"=NAMELSAD,
         "gisjn_plc"=GISJOIN)
    
stores_id1<-stores_raw_sf %>%
  ungroup() %>%
  select(storeid) %>%
  st_join(tracts,join=st_within) %>%
  st_join(places16,join=st_within) 
stores_id2<-stores_id1 %>%
  st_join(pumas16,join=st_intersects) 

stores_id_csv<-stores_id2
st_geometry(stores_id_csv)<-NULL
write_csv(stores_id_csv,"data/snap_retailers_crosswalk.csv")
