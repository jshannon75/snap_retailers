library(tidyverse)
library(sf)
library(tmap)
library(albersusa)

counties<-counties_sf("laea") %>%
  rename(cty_fips=fips)

states<-usa_sf("laea")

stores<-read_csv("data/snap_retailers_usda.csv") 

stores_cw<-read_csv("data/snap_retailers_crosswalk.csv") %>%
  left_join(stores %>% select(store_id,Y2008:Y2019,Y2020)) %>%
  filter(is.na(cty_fips)==FALSE)

ctycount_yr<-stores_cw %>%
  pivot_longer(Y2008:Y2020,names_to="year",values_to="pres") %>%
  filter(pres==1) %>%
  count(cty_fips,year,name = "count") %>%
  group_by(cty_fips) %>%
  mutate(chg=(count-lag(count,1))/lag(count,1)*100) %>%
  ungroup() %>%
  filter(is.na(chg)==FALSE) %>%
  mutate(chg_abs=abs(chg))
   
ctycount_yr_sf<-counties %>%
  inner_join(ctycount_yr)

years<-unique(ctycount_yr$year)

cty_map<-function(year_sel){
  cty_sel<-ctycount_yr_sf %>%
    filter(year==year_sel)
  
  map<-tm_shape(states)+
    tm_polygons(col="#495b78",border.col = "#95a4bd",lwd=1.5)+
  tm_shape(cty_sel)+
    tm_bubbles(col="chg",
               size="chg_abs",
               scale=0.8,
               alpha=0.9,
               title.col="% change from previous year",
               border.alpha=0.4,
               legend.size.show=FALSE,
               breaks=c(-100,-50,-20,0,20,40,60,Inf),
               palette=c("#ad1126","#e6919c","#d9cecf","#ced9cf",
                         "#93c798","#57ab5f","#0c8a18"))+
    tm_layout(frame = FALSE,legend.outside = TRUE,paste("SNAP Retailers in ",
                                                        substr(year_sel,2,5),sep=""))+
    tm_credits("Data from USDA\n Full dataset at https://github.com/jshannon75/snap_retailers",
               position=c(0.5,0.05),size=0.5,
               align="right")
  tmap_save(map,paste("graphics/yearchg/",year_sel,".png",sep=""))
}

cty_map("Y2019")

map_df(years,cty_map)

maps<-paste("graphics/yearchg/",list.files(path="graphics/yearchg/",),sep="")
gifski::gifski(maps,"graphics/snapmaps.gif",delay=0.8)            
