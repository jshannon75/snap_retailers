#Duplicate reduction 10/19/19

library(tidyverse)
library(stringdist)
library(refinr)

#Load store data
stores<-read_csv("data/snap_retailers_usda.csv")

#Identify unique address and create an ID
addr1<-stores %>%
  select(addr_num:state) %>%
  distinct() 

rownum<-nrow(addr1)

addr<-addr1 %>%
  mutate(addr_id=paste("A",str_pad(1:rownum,6,pad="0"),sep=""))

#Join back to main dataset and create a count
stores_count<-stores %>%
  left_join(addr) %>%
  group_by(addr_id,store_type) %>%
  mutate(addr_count=n())

#Identify duplicates and remove capitalization/punctuation
stores_dup<-stores_count %>%
  filter(addr_count > 1) %>%
  mutate(name_lower=tolower(store_name),
         name_punc=str_squish(trimws(gsub("[[:punct:]]", "", name_lower)))) %>%
  select(-name_lower) %>%
  group_by(addr_id,store_type) %>%
  group_split()

#OpenRefine approach
refine_match<-function(df){
  df$match<-n_gram_merge(substr(df$name_punc,1,8))
  df
}

stores_ngram<-map_df(stores_dup,refine_match)

#Combine based on match name
stores_combine<-stores_ngram %>%
  group_by(match,addr_id,store_type) %>%
  summarise(store_id=first(store_id),
            store_name=first(store_name),
            addr_num=first(addr_num),
            addr_st=first(addr_st),
            addr_add=first(addr_add),
            city=first(city),
            state=first(state),
            zip5=first(zip5),
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

stores_nodup<-stores_count %>%
  filter(addr_count==1) %>%
  bind_rows(stores_combine) %>%
  select(-addr_count) %>%
  select(store_id,store_name,addr_id,addr_num,addr_st,addr_add,city,state,zip5,everything())

write_csv(stores_nodup,"data/snap_retailers_usda.csv")

##############stringdist version

#Create grid of combinations
# test<-stores_dup[[1]]
# test1<-expand.grid(test$name_punc,test$name_punc) %>%
#   distinct()

grid_create<-function(df){
  df$match_id<-paste(df$name_punc,df$addr_id,sep=" ;; ")
  expand.grid(df$match_id,df$match_id) %>%
    distinct()
}

grid<-map(stores_dup,grid_create)
grid[[2]]         

#Match the stores.
#Based on inspection, I used a threshhold of 0.12 for this metric (Jaro-Winker Distance).
dist_metric<-0.12

stringdist_grid<-function(df) {
  sdist<-as_tibble(stringdist(df$Var1,df$Var2,method="jw"))
  sdist1<-bind_cols(df,sdist) %>%
    filter(value<dist_metric)
  sdist1$rowid<-as.character(1:nrow(sdist1))
  sdist2<-sdist1 %>%
    gather(Var1,Var2,key="var",value="matchid") %>%
    select(-value,-var) %>%
    distinct()
}

#In this example, rows 2-5 are all the same group. How to combine to a single group?
test<-stringdist_grid(grid[[28]])

grid_dist<-map_df(grid,stringdist_grid)


#This command creates a list that groups similar names with the same address
grid_dist_match<-grid_dist %>%
  distinct() %>%
  separate(matchid,sep=" ;; ",into=c("name_punc","addr_id"))

#Where are stores matched multiple times?
#Need to figure how to then combine these.
#If A=B and B=C and A=C, how to create one group?
trio<-grid_dist_match %>% count(name_punc,addr_id) %>% arrange(n)
tail(trio)

grid_dist_dummy<-grid_dist_match %>%
  mutate(dummy=1) %>%
  spread(rowid,dummy,fill=0)

#Connect back to the store list and combine duplicates
stores_combine <- bind_rows(stores_dup) %>%
  left_join(grid_dist_match) %>%
  distinct()
