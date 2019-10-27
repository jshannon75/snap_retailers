#Removing similar addresses 10/26/19
library(tidyverse)
library(refinr)

stores<-read_csv("data/snap_retailers_usda.csv")

#Identify duplicates and remove capitalization/punctuation
addr_dup<-stores %>%
  mutate(addr_num_na=if_else(is.na(addr_num)==TRUE,"0",addr_num),
    addr_full=paste(addr_num_na,addr_st,sep="")) %>%
  mutate(addr_lower=tolower(addr_full),
         addr_punc=substr(str_squish(trimws(gsub("[[:punct:]]", "", addr_lower))),1,14),
         name_lower=tolower(store_name),
         name_punc=substr(str_squish(trimws(gsub("[[:punct:]]", " ", name_lower))),1,8),
         name_addr=paste(name_punc,addr_punc,sep=" ")) %>%
  select(-addr_lower,-name_lower,-name_punc,-addr_punc) %>%
  group_by(zip5,store_type) %>%
  group_split()

#OpenRefine approach
refine_match<-function(df){
  df$match<-n_gram_merge(df$name_addr)
  df
}

stores_ngram<-map_df(addr_dup,refine_match)

#Inspect results--identified duplicates
stores_ngram_dups<-stores_ngram %>%
  group_by(match,zip5) %>%
  mutate(count=n()) %>%
  filter(count>1) %>%
  select(store_id,zip5,match,name_addr,store_name,addr_num,addr_st)

#Combine stores
stores_combine<-stores_ngram %>%
  group_by(match,zip5,store_type) %>%
  summarise(store_id=first(store_id),
            store_name=first(store_name),
            addr_id=first(addr_id),
            addr_num=first(addr_num),
            addr_st=first(addr_st),
            addr_add=first(addr_add),
            city=first(city),
            state=first(state),
            stype_num=max(stype_num),
            store_group=first(store_group),
            stgrp_num=max(stgrp_num),
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
            method=first(method)) 

stores_combine_save<-stores_combine %>%
  ungroup() %>%
  select(-match) %>%
  select(store_id,store_name,addr_id,addr_num,addr_st,addr_add,city,state,zip5,everything()) %>%
  left_join(stores %>% select(store_id,match))

write_csv(stores_combine_save,"data/snap_retailers_usda.csv")

