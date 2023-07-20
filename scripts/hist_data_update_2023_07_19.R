#Store updates--2021

library(tidyverse)
library(lubridate)
library(sf)

retailer_current<-read_csv("data/hist_snap_retailer_final2021.csv") %>%
  mutate(record_id=as.character(record_id))
retailer_new<-read_csv("data/Historical SNAP Retailer Locator Data 2022.csv") %>%
  rename(record_id=`Record ID`,
         store_name=`Store Name`,
         store_type=`Store Type`,
         street_num=`Street Number`,
         street_name=`Street Name`,
         address_add=`Additional Address`,
         city=City,
         state=State,
         zip=`Zip Code`,
         zip4=Zip4,
         x=Longitude, y= Latitude)%>%
  mutate(auth_date=mdy(`Authorization Date`),
         end_date=mdy(`End Date`)) %>%
  select(-County,-`Authorization Date`,-`End Date`)

#Find only those with 2021 changes
retailer_recent<-retailer_new %>%
  filter(year(auth_date)==2022 | year(end_date)==2022) 

#Combine records with the same ID, name, and address  (which we attribute to lapsed authorization)
retailer_dups1<-retailer_recent %>%
  mutate(end_date1=if_else(is.na(end_date),mdy("12-31-2030"),end_date)) %>%
  group_by(record_id,store_name,store_type,street_num,street_name,address_add, 
           city, state, zip, zip4) %>%
  summarise(y=mean(y),
            x=mean(x),
            auth_date=min(auth_date),
            end_date1=max(end_date1),
            end_date=as.character(end_date1))  %>%
  mutate(end_date=if_else(end_date!="2030-12-31",end_date,""),
         end_date=ymd(end_date)) %>%
  select(-end_date1)

retailer_recent_rev<-retailer_recent %>%
  filter(!`record_id` %in% retailer_dups1$`record_id`) %>%
  bind_rows(retailer_dups1)

#Add additional fields
tracts<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 boundaries/US_tract_2020.gpkg") %>%
  select(STATEFP,COUNTYFP,GEOID,GISJOIN) %>%
  mutate("cty_fips"=paste(STATEFP,COUNTYFP,sep="")) %>%
  rename("st_fips"=STATEFP,
         "tract_fips"=GEOID,
         "gisjn_tct"=GISJOIN) %>%
  select(-COUNTYFP) %>%
  st_transform(4326)
pumas<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 boundaries/US_puma_2020.gpkg") %>%
  st_transform(4326) %>%
  select(GEOID10,GISJOIN) %>%
  rename("puma_fips"=GEOID10,"gisjn_puma"=GISJOIN) %>%
  st_buffer(0)
places<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 boundaries/US_place_2020.gpkg") %>%
  st_transform(4326) %>%
  select("GEOID","NAMELSAD","GISJOIN") %>%
  rename("place_fips"=GEOID,
         "place_name"=NAMELSAD,
         "gisjn_plc"=GISJOIN)
cbsa<-st_read("D:/Dropbox/Jschool/GIS data/Census/NHGIS/2020 boundaries/US_cbsa_2020.gpkg") %>%
  st_transform(4326) %>%
  select(GEOID,NAME,NAMELSAD,LSAD,GISJOIN) %>%
  rename(msa_fips=GEOID,
         msa_name=NAME,
         msaclass_name=NAMELSAD,
         msa_class=LSAD,
         gisjn_msa=GISJOIN)

retail_recent_rev_geo<-retailer_recent_rev %>%
  distinct(record_id,x,y) %>%
  mutate(row_id=row_number()) %>%
  st_as_sf(coords=c("x","y"),crs=4326) %>%
  st_join(tracts,join=st_within) %>%
  st_join(places,join=st_within) %>%
  st_join(cbsa,join=st_within) %>%
  left_join(retailer_recent_rev)

cats_cw<-retailer_current %>%
  distinct(store_type,store_group)

retail_recent_rev_geo1<-retail_recent_rev_geo %>%
  left_join(cats_cw) %>%
  select(-row_id,-geometry)%>% 
  mutate(record_id=as.character(record_id))

##Combine new/old records
retailer_current_keep<-retailer_current %>%
  anti_join(retail_recent_rev_geo1,
            by="record_id") %>%
  bind_rows(retail_recent_rev_geo1)

write_csv(retailer_current_keep,"data/hist_snap_retailer_final2022.csv")

#Create spatial version
retailer_current_keep<-read_csv("data/hist_snap_retailer_final2022.csv")

retailer_current_sf<-retailer_current_keep %>%
  st_as_sf(coords=c("x","y"),crs=4326,remove=FALSE) 

st_write(retailer_current_sf,"data/hist_snap_retailer_final2022.gpkg")

#Create subsets
dollars<-retailer_current_keep %>%
  filter(str_detect(tolower(store_name),"dollar tree") |
           str_detect(tolower(store_name),"dollar general") |
           str_detect(tolower(store_name),"family dollar") |
           str_detect(tolower(store_name),"99 cent"))
write_csv(dollars,"data/dollars.csv")

grocers<-retailer_current_keep %>%
  filter(store_group=="Grocer")
write_csv(grocers,"grocers.csv")

localfoods<-retailer_current_keep %>%
  filter(store_group=="Local foods")
write_csv(localfoods,"data/localfoods.csv")

supermarkets<-retailer_current_keep %>%
  filter(store_group=="Supermarket")
write_csv(supermarkets,"data/supermarkets.csv")

walmart<-retailer_current_keep %>%
  filter(str_detect(tolower(store_name),"walmart")|
           str_detect(tolower(store_name),"wal-mart"))
write_csv(walmart,"data/walmarts.csv")
