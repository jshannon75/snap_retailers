library(tidyverse)
library(readxl)
library(refinr)

#Read in the data
store_types<-read_csv("data/snap_retailers_metadata.csv",skip=48)

stores_2019<-read_excel("data/original USDA data/SNAP Authorized Stores June 2019.xlsx",
                        skip=1) %>%
  rename(store_name=`Store Name`,
         addr_num=`Street Number`,
         addr_st=`Street Name`,
         addr_add=`Addl Address`,
         city=City,
         state=ST,
         zip5=Zip5,
         Y=Latitude,
         X=Longitude,
         st_type=`Store Type`) %>%
  mutate(Y2019=1) 

snap_stores<-read_csv("data/snap_retailers_usda.csv")

#Find duplicates in 2019 stores
addr_dup2019<-stores_2019 %>%
  mutate(addr_num_na=if_else(is.na(addr_num)==TRUE,"0",addr_num),
         addr_full=paste(addr_num_na,addr_st,sep="")) %>%
  mutate(addr_lower=tolower(addr_full),
         addr_punc=substr(str_squish(trimws(gsub("[[:punct:]]", "", addr_lower))),1,14),
         name_lower=tolower(store_name),
         name_punc=substr(str_squish(trimws(gsub("[[:punct:]]", " ", name_lower))),1,13),
         name_addr=paste(name_punc,addr_punc,sep=" ")) %>%
  select(-addr_lower,-name_lower,-name_punc,-addr_punc) %>%
  group_by(zip5,st_type) %>%
  group_split()

refine_match<-function(df){
  df$match<-n_gram_merge(df$name_addr)
  df
}

stores_ngram2019<-map_df(addr_dup2019,refine_match)

#Inspect results
stores_ngram_dups2019<-stores_ngram2019 %>%
  group_by(match,zip5) %>%
  mutate(count=n()) %>%
  filter(count>1) %>%
  select(zip5,match,name_addr,store_name,addr_num,addr_st)

#Combine stores
stores_2019_reduce<-stores_ngram2019 %>%
  group_by(zip5,st_type,match) %>%
  summarise(store_name=first(store_name),
         addr_num=first(addr_num),
         addr_st=first(addr_st),
         addr_add=first(addr_add),
         city=first(city),
         state=first(state),
         Y=first(Y),
         X=first(X),
         method="usda",
         Y2019=1) %>%
  select(-match) %>%
  left_join(store_types)

stores_2019_reduce$tempid<-1:nrow(stores_2019_reduce)

#Match to prior years. Move to all lower case and remove punctuation for name and address
snap_stores_tomatch<-snap_stores %>%
  select(store_id:addr_st,zip5,store_type) %>%
  mutate(addr_num_na=if_else(is.na(addr_num)==TRUE,"0",addr_num),
                 addr_full=paste(addr_num_na,addr_st,sep=" ")) %>%
  mutate(addr_lower=tolower(addr_full),
           addr_punc=str_squish(trimws(gsub("[[:punct:]]", "", addr_lower))),
           name_lower=tolower(store_name),
           name_punc=str_squish(trimws(gsub("[[:punct:]]", " ", name_lower))),
         name_addr=paste(substr(name_punc,1,10),substr(addr_punc,1,12),sep=" ")) %>%
  select(store_id,store_type,zip5,name_addr)%>%
  mutate(df="snap")

snap_2019stores_tomatch<-stores_2019_reduce %>%
  mutate(addr_num_na=if_else(is.na(addr_num)==TRUE,"0",addr_num),
         addr_full=paste(addr_num_na,addr_st,sep=" ")) %>%
  mutate(addr_lower=tolower(addr_full),
         addr_punc=str_squish(trimws(gsub("[[:punct:]]", "", addr_lower))),
         name_lower=tolower(store_name),
         name_punc=str_squish(trimws(gsub("[[:punct:]]", " ", name_lower))),
         name_addr=paste(substr(name_punc,1,10),substr(addr_punc,1,12),sep=" ")) %>% 
  ungroup() %>%
  select(tempid,store_type,zip5,name_addr) 

#Match the stores. We're looking for an exact match.
#For fuzzy duplicates, we'll use the address_duplicates script
snap_matches<-snap_2019stores_tomatch %>%
  left_join(snap_stores_tomatch) %>%
  select(tempid,store_id) %>%
  right_join(stores_2019_reduce) %>%
  select(-tempid)

#Add a Y2019 column to the snap store list
snap_2019_add<-snap_matches %>%
  filter(is.na(store_id)==FALSE) %>%
  select(store_id) %>%
  mutate(Y2019a=1) %>%
  right_join(snap_stores) %>%
  mutate(Y2019=if_else(is.na(Y2019a)==FALSE,1,0)) %>%
  select(-Y2019a)

#Create new store IDs for unmatched stores
snap_id_start<-as.numeric(max(substr(snap_stores$store_id,4,9)))

snap_2019_new<-snap_matches %>%
  filter(is.na(store_id)==TRUE) %>%
  rownames_to_column() %>%
  mutate(store_id=paste("st_",snap_id_start+as.numeric(rowname),sep="")) %>%
  select(-rowname)

snap_2019_full<-bind_rows(snap_2019_add,snap_2019_new) %>%
  replace_na(list(Y2008=0,Y2009=0,Y2010=0,Y2011=0,
                  Y2012=0,Y2013=0,Y2014=0,Y2015=0,
                  Y2016=0,Y2017=0,Y2018=0)) 

write_csv(snap_2019_full,"data/snap_retailers_usda.csv")
