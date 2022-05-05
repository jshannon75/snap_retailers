#Store updates--2021

library(tidyverse)
library(lubridate)

retailer_current<-read_csv("data/hist_snap_retailer_final.csv") %>%
  mutate(record_id=as.character(record_id))
retailer_new<-read_csv("data/Historical SNAP Retailer Locator Data as of 20211231.csv") %>%
  mutate(auth_date=mdy(`Authorization Date`),
         end_date=mdy(`End Date`))

#Find only those with 2021 changes
retailer_recent<-retailer_new %>%
  filter(year(auth_date)==2021 | year(end_date)==2021) 

#Combine records with the same ID, name, and address (which we attribute to lapsed authorization)
#Existing records
retailer_currdup<-retailer_current %>%
  group_by(record_id,store_name) %>%
  mutate(auth_date=mdy(auth_date),
         end_date=mdy(end_date)) %>%
  mutate(count=n(),
         combine=if_else(count>1,1,0),
         na_end=if_else(is.na(end_date),1,0)) %>%
  summarise(auth_date=min(auth_date),
            auth_year=min(auth_year),
            end_date=if_else(max(na_end)==1,"",max(end_date)),
            end_year=if_else(max(na_end)==1,"",max(end_year)))
  


retailer_dups<-retailer_recent %>%
  group_by(`Record ID`,`Store Name`) %>%
  mutate(count=n()) %>%
  filter(count>1) %>%
  mutate(gap=as.integer(auth_date-lag(end_date,1))) %>%
  mutate(combine=if_else(gap<91,1,0),
         combine=if_else)
         