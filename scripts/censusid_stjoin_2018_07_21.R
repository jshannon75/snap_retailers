#This script adds county, tract, PUMA, MSA, and city IDs to the SNAP store data.
library(tidyverse)
library(sf)

#Read in data ####
stores_raw<-read_csv("data/snap_retailers_usda.csv")

#Identify stores without a match
stores_raw<-read_csv("data/snap_retailers_usda.csv")

cw_old<-read_csv("data/snap_retailers_crosswalk.csv")
stores_match<-stores_raw %>%
  inner_join(cw_old)

stores_nomatch<-stores_raw %>%
  anti_join(cw_old)

stores_nomatch_sf<-st_as_sf(stores_nomatch,coords=c("X","Y"),crs=4326)

#Load geospatial data
tracts<-st_read("analysis_NO_UPLOAD/data/nhgis_boundaries/nhgis0101_shapefile_tl2017_us_tract_2017/US_tracts_2017.shp") %>%
  select(STATEFP,COUNTYFP,GEOID,GISJOIN) %>%
  mutate("cty_fips"=paste(STATEFP,COUNTYFP,sep="")) %>%
  rename("st_fips"=STATEFP,
         "tract_fips"=GEOID,
         "gisjn_tct"=GISJOIN) %>%
  select(-COUNTYFP) %>%
  st_transform(4326)
pumas<-st_read("analysis_NO_UPLOAD/data/nhgis_boundaries/nhgis0102_shapefile_tl2017_us_puma_2017/US_puma_2017.shp") %>%
  st_transform(4326) %>%
  select(GEOID10,GISJOIN) %>%
  rename("puma_fips"=GEOID10,"gisjn_puma"=GISJOIN) %>%
  st_buffer(0)
places<-st_read("analysis_NO_UPLOAD/data/nhgis_boundaries/nhgis0101_shapefile_tl2017_us_place_2017/US_place_2017.shp") %>%
  st_transform(4326) %>%
  select("GEOID","NAMELSAD","GISJOIN") %>%
  rename("place_fips"=GEOID,
         "place_name"=NAMELSAD,
         "gisjn_plc"=GISJOIN)
cbsa<-st_read("analysis_NO_UPLOAD/data/nhgis_boundaries/nhgis0101_shapefile_tl2017_us_cbsa_2017/US_cbsa_2017.shp") %>%
  st_transform(4326) %>%
  select(GEOID,NAME,NAMELSAD,LSAD,GISJOIN) %>%
  rename(msa_fips=GEOID,
         msa_name=NAME,
         msaclass_name=NAMELSAD,
         msa_class=LSAD,
         gisjn_msa=GISJOIN)
    
stores_id1<-stores_nomatch_sf %>%
  ungroup() %>%
  select(store_id) %>%
  st_join(tracts,join=st_within) %>%
  st_join(places,join=st_within) %>%
  st_join(cbsa,join=st_within) 
stores_id2<-stores_id1 %>%
  st_join(pumas,join=st_within) 

stores_id_csv<-stores_id2 %>%
  mutate(msa_fips=as.numeric(msa_fips)) %>%
  st_set_geometry(NULL) %>%
  bind_rows(cw_old)

stores_id3<-stores_raw %>%
  st_as_sf(coords=c("X","Y"),crs=4326,remove=FALSE) %>%
  inner_join(stores_id_csv) 

write_csv(stores_id_csv,"data/snap_retailers_crosswalk.csv")
st_write(stores_id3,"analysis_NO_UPLOAD/data/snap_retailers_full.gpkg")
