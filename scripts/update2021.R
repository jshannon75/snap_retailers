
#Read in 2021 data

library(tidyverse)
library(lubridate)
library(sf)

snap_retail<-read_csv("data/hist_snap_retailer_final.csv") %>%
  mutate(zip=str_pad(as.character(zip),5,pad="0"),
         zip4=str_pad(as.character(zip4),4,pad="0"),
         msa_fips=as.character(msa_fips))
hist(snap_retail$auth_year)

#Read in new retailers and keep those that have changed in 2021

retail2021<-read_csv("data/Historical SNAP Retailer Locator Data as of 20211231.csv") %>%
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

#New retailers with geo info
retail2021_new<-retail2021  %>%
  filter(auth_date>mdy("12/31/2020")) 

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
bg<-st_read("analysis_NO_UPLOAD/data/US_blck_grp_2010.gpkg") %>%
  select(GEOID10,GISJOIN) %>%
  rename(fips_bg=GEOID10,
         gisjn_bg=GISJOIN)

retail2021_new_sf<-retail2021_new %>%
  distinct(record_id,x,y) %>%
  mutate(row_id=row_number()) %>%
  st_as_sf(coords=c("x","y"),crs=4326) %>%
  st_join(tracts,join=st_within) %>%
  st_join(places,join=st_within) %>%
  st_join(cbsa,join=st_within) %>%
  st_join(bg,join=st_within)
  left_join(retail2021_new)

cats_cw<-snap_retail %>%
  select(store_type,store_group) %>%
  distinct()

retailer2021_new_cat <-retail2021_new_sf %>%
  st_set_geometry(NULL) %>%
  left_join(cats_cw)

#Update already present stores
retail2021_closed<-retail2021 %>%
  filter(end_date>mdy("12/31/2020") & auth_date<mdy("12/31/2020")) 

snapretail_noend<-snap_retail %>%
  filter(is.na(end_date)) %>%
  inner_join(retail2021_closed %>% select(record_id)) 

snapretail_base<-snap_retail %>%
  anti_join(snapretail_noend)

snapretail_update<-snapretail_noend %>%
  select(-end_date) %>%
  mutate(auth_date=mdy(auth_date)) %>%
  left_join(retail2021_closed %>% 
              select(record_id,end_date))

#Combine and save
retail_new<-snapretail_base %>%
  mutate(end_date=mdy(end_date),
         auth_date=mdy(auth_date)) %>%
  bind_rows(snapretail_update,
            reailer2021_new_sf %>%st_set_geometry(NULL)) %>%
  mutate(auth_year=year(auth_date),
         end_year=year(end_date))

hist(retail_new$auth_year)

write_csv(retail_new,"data/hist_snap_retailer_final2021.csv",na="")

st_write(retail_new %>% st_as_sf(coords=c("x","y"),crs=4326,remove=FALSE),
         "data/hist_snap_retailer_final2021a.gpkg",delete_dsn=TRUE)


