library(tidyverse)

snap_data<-read_csv("data/Historical SNAP Retailer Locator Data as of 20201231_geocode.csv")
table(snap_data$GeocodeMethod)

#Check for duplication
snap_data_dup<-snap_data %>%
  count(store_name,street_num,street_name,street_num) %>%
  filter(n>1)

snap_data_dupsonly <-snap_data %>%
  inner_join(snap_data_dup)

#Join broad store classifications
snap_old<-read_csv("data/snap_retailers_usda.csv") %>%
  distinct(store_type,store_group) %>%
  filter(is.na(store_group)==FALSE)

snap_data1<-snap_data %>%
  left_join(snap_old) %>%
  select(record_id,store_name,store_type,store_group,everything())

write_csv(snap_data1,"data/Historical SNAP Retailer Locator Data as of 20201231_geocode.csv",na = "")
