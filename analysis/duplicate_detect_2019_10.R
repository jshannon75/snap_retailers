library(tidyverse)

snap<-read_csv("data/snap_retailers_usda.csv") 

snap_dup<-snap %>%
  group_by(store_name,addr_num,addr_st,addr_add,
           city,state,zip5,store_type,stype_num,st_type,
           store_group,stgrp_num) %>%
  summarise(count=n(),
            store_id=first(storeid),
            Y2008=max(Y2008),
            Y2009=max(Y2009),
            Y2010=max(Y2010),
            Y2011=max(Y2011),
            Y2012=max(Y2012),
            Y2013=max(Y2013),
            Y2014=max(Y2014),
            Y2015=max(Y2015),
            Y2016=max(Y2016),
            Y2017=max(Y2017),
            Y2018=max(Y2018),
            X=first(X),
            Y=first(Y),
            method=first(method),
            match=first(match))

write_csv(snap_dup,"data/snap_retailers_usda.csv")
