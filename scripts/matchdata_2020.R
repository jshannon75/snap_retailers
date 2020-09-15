library(tidyverse)
library(readxl)
library(albersusa)

storeclass<-read_csv("data/snap_retailers_metadata.csv",
                     skip=48)
states<-usa_sf("laea") %>%
  rename(ST=iso_3166_2)

jandata<-read_xlsx("data/original USDA data/SNAP Authorized Stores 01-30-20.xlsx",
                   skip=1)
junedata<-read_xlsx("data/original USDA data/SNAP Authorized Stores 06-30-20.xlsx",
                    skip=1)

jan_match<-jandata %>%
  select(`Store Name`,`Street Number`,`Street Name`,Zip5) %>%
  mutate(janid=paste("S",row_number(),sep=""))

junematched<-junedata %>%
  mutate(junestore=1) %>%
  full_join(jan_match)

jan_nonmatch<-jan_match %>%
  anti_join(junematched)

june_nonmatch<-junematched %>%
  filter(is.na(janid)==TRUE)

tablejan<-jandata %>%
  left_join(storeclass %>%
              mutate(`Store Type`=st_type)) %>% 
  group_by(ST,store_group) %>%
  summarise(jan=n()) 

tablejune<-junedata %>%
  ungroup() %>%
  left_join(storeclass %>%
              mutate(`Store Type`=st_type)) %>%
  group_by(ST,store_group) %>%
  summarise(june=n()) %>%
  full_join(tablejan) %>%
  filter(is.na(june)==FALSE & is.na(jan)==FALSE) %>%
  mutate(change=june/jan*100-100) %>%
  filter(is.na(store_group)==FALSE)

tablewide<-table_june %>%
  select()
  pivot_wider()

ggplot(tablejune,aes(x=change,y=ST,color=ST))+
  geom_point()+
  facet_wrap(~store_group,scales="free")

table_geo<-states %>%
  left_join(tablejune)

ggplot(table_geo)+
  geom_sf(aes(fill=change)) +
  facet_wrap(~store_group)

library(tmap)
map<-tm_shape(table_geo)+
  tm_polygons("change",
              palette="PRGn",
              breaks=c(-50,-20,0,10,20,40,60))+
  tm_facets(by="store_group",nrow=2)  
tmap_save(map,"graphics/janjune_stchange.pdf",
          height=3,width=7)
