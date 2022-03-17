library(tidyverse)
library(sf)

# regions<-read_csv("D:/Dropbox/Jschool/GIS data/Census/state_regional codes.csv")
# 
# ua_cluster<-st_read("data/US_ua_2020.gpkg") %>%
#   filter(UATYP10=="C") %>%
#   separate(NAME10,into=c("ua","st_abbr"),sep=", ",remove=FALSE) %>%
#   mutate(st_abbr=substr(st_abbr,1,2)) %>%
#   select(GISJOIN,NAME10,GEOID10,st_abbr) %>%
#   rename(gisjn_ua=GISJOIN,
#          name_ua=NAME10,
#          fips_ua=GEOID10) %>%
#   st_transform(4326) %>%
#   left_join(regions)
# 
# dollars<-st_read("data/dg.gpkg") %>%
#   mutate(type="dg")
# grocers<-st_read("data/grocers.gpkg") %>%
#   mutate(type="grocer")
# supers<-st_read("data/supers.gpkg") %>%
#   mutate(type="super")
# walmart<-st_read("data/walmart.gpkg") %>%
#   mutate(type="walmart")
# cents<-st_read("data/99cents.gpkg") %>%
#   mutate(type="99cent")
# 
# allstores_uc<-bind_rows(dollars,grocers,supers,walmart,cents) %>%
#   st_join(ua_cluster,join=st_within) %>%
#   filter(is.na(gisjn_ua)==FALSE) %>%
#   st_set_geometry(NULL)
# 
# store_count<-function(year_sel){
#   allstores_uc %>%
#     mutate(end_year=if_else(is.na(end_year),2022,end_year)) %>%
#     filter(auth_year <= year_sel & end_year >= year_sel) %>%
#     count(type,gisjn_ua,name_ua,fips_ua,STATE,Region,Division,name="count") %>%
#     mutate(year=paste("Y",year_sel,sep=""))
# }
# 
# years<-2008:2021
# 
# store_counts<-map_df(years,store_count) %>%
#   pivot_wider(names_from=type,values_from=count,values_fill=0) %>%
#   group_by(name_ua) %>%
#   mutate(dg_add=if_else(dg>lag(dg,1),1,0),
#          grocer_drop=if_else(grocer<lag(grocer,1),1,0),
#          super_drop=if_else(super<lag(super,1),1,0))
#
# write_csv(store_counts,"data/ua_counts_2022_03_15.csv")
store_counts<-read_csv("data/ua_counts_2022_03_15.csv") %>%
  group_by(name_ua) %>%
  mutate(super_drop1=if_else(lead(super,1)<super,1,0),
         dg_add1=if_else(lead(dg,1)>dg,1,0))

##Need to create variables for each scenario ()

table(store_counts$dg_add)
table(store_counts$grocer_drop)
table(store_counts$super_drop)
table(store_counts$super_drop1)

model_grocer <- glm(grocer_drop~dg_add+Region, data=store_counts, family="binomial")
summary(model_grocer)

model_dg<-glm(dg_add~grocer_drop+Region, data=store_counts, family="binomial")
summary(model_dg)

model_super <- glm(super_drop1~dg_add+Region, data=store_counts, family="binomial")
summary(model_super)
model_dg1 <- glm(dg_add1~super_drop+Region, data=store_counts, family="binomial")
summary(model_dg1)

#Count of stores overall by year and region
region_count<-store_counts %>%
  group_by(Region,year) %>%
  summarise(`99cent`=sum(`99cent`),
            dg=sum(dg),
            grocer=sum(grocer),
            super=sum(super),
            walmart=sum(walmart)) %>%
  pivot_longer(`99cent`:walmart,names_to="type",values_to="count") %>%
  pivot_wider(names_from=year,values_from=count)

write_csv(region_count,"data/region_counts_2022_03_15.csv")
