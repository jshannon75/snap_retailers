##Create the geopackage data for the Shiny application

library(tidyverse)
library(sf)

#Read the store data
stores1<-read_csv("data/snap_retailers_crosswalk.csv")
stores<-read_csv("data/snap_retailers_usda.csv") %>%
  left_join(stores1)

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
