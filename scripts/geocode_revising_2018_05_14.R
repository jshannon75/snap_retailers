library(tidyverse)
library(ggmap)
library(sf)
library(tmaptools)

#This script reviews ESRI geocoded addresses and uses the Google API to geocode ones with poor precision.


################################
##Examine geocoded addresses ####
snap_geocode<-read_csv("data/snap_retailers_natl_noxy_2018_02_13.csv") %>%
  mutate(zip5=if_else(nchar(zip5)<5,paste(0,zip5,sep=""),as.character(zip5)), #Add leading 0s
         zip5=if_else(nchar(zip5)<5,paste(0,zip5,sep=""),as.character(zip5)),
         full_add=paste(addr_all,city_1,state,zip5,sep=","))
table(snap_geocode$Addr_type)

snap_geocode_locality<-snap_geocode %>%
  filter(Addr_type=="Locality") #A lot of St. Croix. 0's are left out of zip. Will leave be for now, as there's only 15.

snap_geocode_poi<-snap_geocode %>%
  filter(Addr_type=="POI") #These look mostly OK. List things like shopping malls, etc.

snap_geocode_postal<-snap_geocode %>%
  filter(Addr_type=="Postal") #Most of these are zip code centroids with no good address

snap_geocode_postalloc<-snap_geocode %>%
  filter(Addr_type=="PostalLoc") #Run through Google? Modified Zip code but multiple good addresses.

snap_geocode_staddext<-snap_geocode %>%
  filter(Addr_type=="StreetAddressExt") #Technically out of range. 

snap_geocode_stint<-snap_geocode %>%
  filter(Addr_type=="StreetInt") #Street intersections. These are fine.

snap_geocode_stname<-snap_geocode %>%
  filter(Addr_type=="StreetName") #Says it's just where there's a street name only, but there's several with addresses

snap_geocode_subadd<-snap_geocode %>%
  filter(Addr_type=="Subaddress") #With apts, etc. These are fine.

plot(snap_geocode$X,snap_geocode$Y)

####################
## geocode data w/Google ####
#Generally keeping rooftop, range interpolated, and geometric center

register_google(key = "key goes here", account_type = "premium", day_limit = 100000)
ggmap_credentials()


#Locality (leave be)
snap_geocode_locality_gc<-snap_geocode_locality %>% 
  mutate_geocode(full_add,output="more")

#Postal
#snap_geocode_postal_gc<-snap_geocode_postal %>% 
#  mutate_geocode(full_add,output="more")
#write_csv(snap_geocode_postal_gc,"data/snap_retailers_natl_noxy_postal_2018_05_15.csv")
snap_geocode_postal_gc<-read_csv("data/old/snap_retailers_natl_noxy_postal_2018_05_15.csv") %>%
  filter(loctype %in% c("rooftop","range_interpolated","geometric_center")) %>%
  mutate(X=lon,
         Y=lat,
         method="google",
         match=loctype) %>%
  select(-lon:-campground)


#Postal_loc
# snap_geocode_postalloc_gc<-snap_geocode_postalloc %>% 
#   mutate_geocode(full_add,output="more")
# write_csv(snap_geocode_postalloc_gc,"data/snap_retailers_natl_noxy_postalloc_2018_05_15.csv")
snap_geocode_postalloc_gc<-read_csv("data/old/snap_retailers_natl_noxy_postalloc_2018_05_15.csv") %>%
  filter(loctype %in% c("rooftop","range_interpolated","geometric_center")) %>%
  mutate(X=lon,
         Y=lat,
         method="google",
         match=loctype) %>%
  select(-lon:-locality.1)

#Street address extended
#snap_geocode_staddext_gc<-snap_geocode_staddext %>% 
#  mutate_geocode(full_add,output="more")
#write_csv(snap_geocode_staddext_gc,"data/snap_retailers_natl_noxy_staddext_2018_05_15.csv")
snap_geocode_staddext_gc<-read_csv("data/old/snap_retailers_natl_noxy_staddext_2018_05_15.csv") %>%
  filter(loctype %in% c("rooftop","range_interpolated","geometric_center")) %>%
  mutate(X=lon,
         Y=lat,
         method="google",
         match=loctype) %>%
  select(-lon:-premise.1)

#Street name part 1
# snap_geocode_stname_gc<-snap_geocode_stname[1:900,] %>% 
#   mutate_geocode(full_add,output="more")
# write_csv(snap_geocode_stname_gc,"data/snap_retailers_natl_noxy_stname1_2018_05_15.csv")
snap_geocode_stname1_gc<-read_csv("data/old/snap_retailers_natl_noxy_stname1_2018_05_15.csv") %>%
  filter(loctype %in% c("rooftop","range_interpolated","geometric_center")) %>%
  mutate(X=lon,
         Y=lat,
         method="google",
         match=loctype) %>%
  select(-lon:-premise)

#Remove store names that result in errors with Google (just stick with ESRI geocoding)
snap_geocode_stname<-snap_geocode_stname %>% 
  filter(storeid!="st_118017" & storeid!="st_159999")

# #Street name part 2
# snap_geocode_stname_gc<-snap_geocode_stname[901:1100,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc1<-snap_geocode_stname[1101:1300,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc2<-snap_geocode_stname[1301:1800,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc3<-snap_geocode_stname[1801:2100,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc4<-snap_geocode_stname[2101:2400,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc5<-snap_geocode_stname[2401:2600,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc6<-snap_geocode_stname[2601:2918,] %>% 
#   mutate_geocode(full_add,output="more")
# snap_geocode_stname_gc_all<-snap_geocode_stname_gc %>%
#   bind_rows(snap_geocode_stname_gc1) %>%
#   bind_rows(snap_geocode_stname_gc2) %>%
#   bind_rows(snap_geocode_stname_gc3) %>%
#   bind_rows(snap_geocode_stname_gc4) %>%
#   bind_rows(snap_geocode_stname_gc5) %>%
#   bind_rows(snap_geocode_stname_gc6)
# write_csv(snap_geocode_stname_gc_all,"data/snap_retailers_natl_noxy_stname2_2018_05_15.csv")

snap_geocode_stname2_gc<-read_csv("data/old/snap_retailers_natl_noxy_stname2_2018_05_15.csv") %>%
  filter(loctype %in% c("rooftop","range_interpolated","geometric_center")) %>%
  mutate(X=lon,
         Y=lat,
         method="google",
         match=loctype) %>%
  select(-lon:-post_box)

#Merge files with Google data
snap_geocode_google_gc<-snap_geocode_postal_gc %>%
  bind_rows(snap_geocode_postalloc_gc) %>%
  bind_rows(snap_geocode_staddext_gc) %>%
  bind_rows(snap_geocode_stname1_gc) %>%
  bind_rows(snap_geocode_stname2_gc)

snap_google_id<-snap_geocode_google_gc %>% select(store_name,storeid)

snap_geocode_esri<-anti_join(snap_geocode,snap_google_id) %>%
  mutate(method="esri",
         match=Addr_type) 

snap_geocode_all<-bind_rows(snap_geocode_esri,snap_geocode_google_gc)
write_csv(snap_geocode_all,"data/snap_retailers_natl_geocode_2018_05_17.csv")

#Merge geocoded addresses with all addresses
snap_geocode_all<-read_csv("data/snap_retailers_natl_geocode_2018_05_17.csv")
snap_geocode_all<-snap_geocode_all %>% 
  select(-Score:-full_add)
snap_all<-read_csv("data/snap_retailers_natl_2018_02_13.csv") %>%
  select(-addr_num:-zip5) 

snap_all1<-read_csv("data/old/snap_retailers_natl_2018_01_03.csv") %>%
  mutate(addr_all=paste(addr_num,addr_st,sep=" "),
         zip5=as.character(zip5))

snap_all2<-left_join(snap_all,snap_all1)

snap_geocode_id<-snap_geocode_all %>% select(store_name,storeid)
snap_geocode_usda<-anti_join(snap_all2,snap_geocode_id) %>%
  rename("X"=long,"Y"=lat) %>%
  mutate(method="usda",
         match="")  %>%
  rename("city_1"=city,
         "state"=st)
snap_all_comb<-bind_rows(snap_geocode_all,snap_geocode_usda)

write_csv(snap_all_comb,"data/snap_retailers_natl_2018_06_11.csv")


#Identify problem geocodes--where location doesn't match state
#This is from a master list like the one on l. 178
snap_all_comb<-read_csv("analysis_NO_UPLOAD/data/storepoints_all.csv")

states<-snap_all_comb %>% 
  select(state,st_fips) %>% 
  group_by(state) %>% 
  count(st_fips) %>%
  filter(n<20) %>%
  select(-n)

store_problems<-states %>% 
  left_join(snap_all_comb) %>%
  mutate(cityadd=paste(city,", ",state,sep=""))

store_problems1<-store_problems %>%
  mutate_geocode(cityadd,output="more") 

store_problems2<-store_problems1 %>%
  mutate(X=lon,Y=lat,
         method="google",
         match=loctype) %>%
  select(state:dup,-st_fips) %>%
  rename("store_name"=`5`)

store_problems_inspect<-store_problems1 %>%
  select(state,administrative_area_level_1) %>%
  mutate(X=)
