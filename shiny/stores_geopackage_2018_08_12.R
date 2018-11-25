##Create the geopackage data for the Shiny application and data for the analysis

library(tidyverse)
library(sf)

#Read the store data
stores<-read_csv("analysis_NO_UPLOAD/data/storepoints_all.csv")
stores_sf<-st_as_sf(stores,coords=c("X","Y"),crs=4326,remove=FALSE)
stores_sf<-st_write(stores_sf,"analysis_NO_UPLOAD/data/storepoints_all.gpkg",delete_layer=TRUE)

#Write to the github repo
stores_usda<-stores %>% select(store_name:dup)
stores_crosswalk<-stores %>% select(store_name,storeid,st_fips:gisjn_puma)

write_csv(stores_usda,"data/snap_retailers_usda.csv")
write_csv(stores_crosswalk,"data/snap_retailers_crosswalk.csv")

#County list
counties<-st_read("C:/Users/jshannon/Dropbox/Jschool/GIS data/Census/US_counties/2012 Counties/US_county_2012.shp")
st_geometry(counties)<-NULL

states<-stores %>% 
  select(state,st_fips) %>% 
  mutate(st_fips=substr(st_fips,2,3)) %>%
  distinct()

counties_sm<-counties %>% 
  select(NAMELSAD,STATEFP,COUNTYFP,GEOID) %>%
  rename("county"=NAMELSAD,
         "st_fips"=STATEFP,
         "cty_fips"=COUNTYFP,
         "stcty_fips"=GEOID) %>%
  left_join(states) %>%
  mutate(fullname=paste(county,state,sep=", "))

write_csv(counties_sm,"shiny/county_list.csv")

#Read in the biggest five MSAs in each census region
msa5<-read_csv("shiny/msa5_ranks_2018_07_25.csv") 
stores_msa5<-stores %>%
  filter(msa_fips %in% msa5$GEOID)

#Create a function that filters stores by MSA and writes them to the geopackage
msa_write<-function(msa_id){
  stores_select<-stores_msa5 %>%
    filter(msa_fips==msa_id)
  
  stores_select_sf<-st_as_sf(stores_select,coords=c("X","Y"),crs=4326,remove=FALSE)
  filename<-paste("G",msa_id,sep="")
  st_write(stores_select_sf,"shiny/storepoints_msa5.gpkg",layer=filename,delete_layer=TRUE)
}

map(msa5$GEOID,msa_write)

#Write all files to a geopackage
state_write<-function(st_id){
  stores_select<-stores %>%
    filter(st_fips==st_id)
  
  stores_select_sf<-st_as_sf(stores_select,coords=c("X","Y"),crs=4326,remove=FALSE)
  filename<-paste(st_id,sep="")
  st_write(stores_select_sf,"shiny/storepoints_state.gpkg",layer=filename,delete_layer=TRUE)
}

states<-stores %>% 
  select(st_fips) %>% 
  filter(is.na(st_fips)==FALSE) %>%
  distinct()

map(states$st_fips,state_write)

