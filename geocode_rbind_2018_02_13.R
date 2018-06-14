library(tidyverse)

snap_all<-read_csv("data/old/snap_retailers_natl_2018_01_03.csv") %>%
  filter(lat>-30) #To remove 0s
snap_geocode<-read_csv("data/snap_retailers_natl_noxy_2018_02_13.csv") %>%
  select(-Score,-Match_type,-Addr_type) %>%
  rename("long"=X,"lat"=Y) %>%
  bind_rows(snap_all)

write_csv(snap_geocode,"data/old/snap_retailers_natl_2018_02_13.csv")
