#This script adds county, tract, PUMA, MSA, and city IDs to the SNAP store data.
library(tidyverse)
library(sf)
library(lubridate)
library(furrr)
future::plan(multicore)

#Read in data ####
stores_raw1<-read_csv("data/Historical SNAP Retailer Locator Data as of 20201231_geocode.csv")

#fix xy swap
stores_xyswap<-stores_raw1 %>%
  filter(x>0 & y<0) %>%
  mutate(x1=y,y1=x) %>%
  select(-x,-y) %>%
  rename(x=x1,y=y1)

stores_raw<-stores_raw1 %>%
  anti_join(stores_xyswap,by=c("record_id","store_name","address_add","auth_date")) %>%
  bind_rows(stores_xyswap)

#Load geospatial data
tracts<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 tracts pumas msa place/US_tract_2020.gpkg") %>%
  select(STATEFP,COUNTYFP,GEOID,GISJOIN) %>%
  mutate("cty_fips"=paste(STATEFP,COUNTYFP,sep="")) %>%
  rename("st_fips"=STATEFP,
         "tract_fips"=GEOID,
         "gisjn_tct"=GISJOIN) %>%
  select(-COUNTYFP) %>%
  st_transform(4326)
pumas<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 tracts pumas msa place/US_puma_2020.gpkg") %>%
  st_transform(4326) %>%
  select(GEOID10,GISJOIN) %>%
  rename("puma_fips"=GEOID10,"gisjn_puma"=GISJOIN) %>%
  st_buffer(0)
places<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 tracts pumas msa place/US_place_2020.gpkg") %>%
  st_transform(4326) %>%
  select("GEOID","NAMELSAD","GISJOIN") %>%
  rename("place_fips"=GEOID,
         "place_name"=NAMELSAD,
         "gisjn_plc"=GISJOIN)
cbsa<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 tracts pumas msa place/US_cbsa_2020.gpkg") %>%
  st_transform(4326) %>%
  select(GEOID,NAME,NAMELSAD,LSAD,GISJOIN) %>%
  rename(msa_fips=GEOID,
         msa_name=NAME,
         msaclass_name=NAMELSAD,
         msa_class=LSAD,
         gisjn_msa=GISJOIN)
    
pumajoin_all_sf<-stores_raw %>%
  distinct(record_id,x,y) %>%
  mutate(row_id=row_number()) %>%
  st_as_sf(coords=c("x","y"),crs=4326) %>%
  st_join(tracts,join=st_within) %>%
  st_join(places,join=st_within) %>%
  st_join(cbsa,join=st_within) %>%
  left_join(stores_raw)

st_write(pumajoin_all_sf,"data/hist_snap_retailer1.gpkg",delete_dsn = TRUE)

#Puma join in qgis and reduce duplicates

pumajoin<-st_read("data/hist_snap_retailer.gpkg")%>%
  st_set_geometry(NULL)
otherjoin<-st_read("data/hist_snap_retailer1.gpkg")%>%
  st_set_geometry(NULL)

puma_reduce<-function(df){
  pumajoin %>%
    group_by(record_id,x,y) %>%
    summarise(puma_fips=first(puma_fips),
            gisjn_puma=first(gisjn_puma))
}

options(future.globals.maxSize = 1000000000)
pumajoin1<-future_map(pumajoin,puma_reduce)

pumajoin2<-data.frame(pumajoin1) %>%
  select(puma_fips.record_id,puma_fips.puma_fips,puma_fips.gisjn_puma) %>%
  distinct()
names(pumajoin2)<-c("record_id","puma_fips","gisjn_puma") 

pumajoin_all <-otherjoin %>%
  left_join(pumajoin2) %>%
  mutate(auth_year=year(mdy(auth_date)),
         end_year=year(mdy(end_date)))%>%
  select(record_id,store_name:zip4,auth_date,auth_year,end_date,end_year,x,y,county,cty_fips,tract_fips,gisjn_tct,
         st_fips,place_fips:gisjn_msa,puma_fips,gisjn_puma) 

pumajoin_all_sf<-pumajoin_all %>% 
  st_as_sf(coords=c("x","y"),crs=4326,remove=FALSE)

write_csv(pumajoin_all,"data/hist_snap_retailer_final.csv",na="")
st_write(pumajoin_all_sf %>% st_as_sf(coords=c("x","y"),crs=4326,remove=FALSE),
         "data/hist_snap_retailer_final.gpkg",delete_dsn=TRUE)

#DG analysis

#pumajoin_all_sf<-st_read("data/hist_snap_retailer_final.gpkg")
dg<-pumajoin_all_sf %>%
  filter(str_detect(tolower(store_name),"dollar general")) %>%
  mutate(auth_date1=year(mdy(auth_date)))
st_write(dg,"data/dg.gpkg",delete_dsn = TRUE)

walmart<-pumajoin_all_sf %>%
  filter(str_detect(tolower(store_name),"walmart")) %>%
  mutate(auth_date1=year(mdy(auth_date)))
st_write(walmart,"data/walmart.gpkg",delete_dsn = TRUE)

hist(dg$auth_date1)

supers<-pumajoin_all_sf %>%
  filter(store_group=="Supermarket")%>%
  mutate(auth_date1=year(mdy(auth_date)))
st_write(supers,"data/supers.gpkg",delete_dsn = TRUE)

grocers<-pumajoin_all_sf %>%
  filter(store_group=="Grocer")%>%
  mutate(auth_date1=year(mdy(auth_date)))
st_write(grocers,"data/grocers.gpkg",delete_dsn = TRUE)

cents<-pumajoin_all_sf %>%
  filter(str_detect(tolower(store_name),"99 cent"))%>%
  mutate(auth_date1=year(mdy(auth_date)))
st_write(cents,"data/99cents.gpkg",delete_dsn = TRUE)



hist(supers$auth_date1)
