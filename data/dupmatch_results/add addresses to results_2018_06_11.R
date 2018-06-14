library(tidyverse)
library(stringdist)

add_match<-read_csv("data/zane_results/snap_matches_from_addresses.csv")
name_match<-read_csv("data/zane_results/snap_matches_from_names.csv")

store_id<-read_csv("data/snap_retailers_natl_2018_06_11.csv") %>%
  select(storeid,addr_all,addr_add,city_1,state,zip5) %>%
  rename("store1name"=storeid)
store_id1<-rename(store_id,"store2name_1"=store1name)

add_match1<-add_match %>%
  left_join(store_id) %>%
  unite(address1,addr_all:zip5) %>%
  left_join(store_id1) %>%
  unite(address2,addr_all:zip5) %>%
  distinct() %>%
  mutate(add_dist=stringdist(address1,address2))

write_csv(add_match1,"data/zane_results/snap_mattches_from_addresses1.csv")

name_match1<-name_match %>%
  left_join(store_id) %>%
  unite(address1,addr_all:zip5) %>%
  left_join(store_id1) %>%
  unite(address2,addr_all:zip5) %>%
  distinct() %>%
  mutate(add_dist=stringdist(address1,address2))

write_csv(name_match1,"data/zane_results/snap_matches_from_names1.csv")
