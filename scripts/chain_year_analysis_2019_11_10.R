library(sf)
library(tidyverse)
library(tmap)
library(tidycensus)
library(BAMMtools)
library(gifski)

stores_raw<-read_csv("data/snap_retailers_usda.csv")
stores<-read_csv("data/snap_retailers_crosswalk.csv") %>%
  left_join(stores_raw)

chain_name<-"Wawa"
chain<-stores %>%
  mutate(store1=tolower(store_name)) %>%
  filter(grepl(tolower(chain_name),store1)) 

chain_cty<-chain %>%
  gather(Y2008:Y2019,key=year,value=pres) %>%
  filter(pres==1) %>%
  count(cty_fips,year,name="count") %>%
  rename(GEOID=cty_fips)

cty_pop<-get_acs(geography="county",variable="B01001_001",year=2017,
                 shift_geo=TRUE,geometry=TRUE)

cty_geom<-cty_pop %>%
  select(geometry,GEOID)

cty_total<-cty_pop %>%
  left_join(chain_cty) %>%
  mutate(year=replace_na(year,"Y2008")) %>%
  select(-moe) %>%
  st_set_geometry(NULL) %>%
  spread(year,count,fill=0) %>%
  gather(Y2008:Y2019,key=year,value=count) %>%
  mutate(density=round(count/estimate*100000,1))

cty_map<-cty_geom %>%
  left_join(cty_total) %>%
  mutate(year_num=as.integer(substr(year,2,5)))

states<-get_acs(geography="state",variable="B01001_001",year=2017,
                shift_geo=TRUE,geometry=TRUE)

#yr=2019
cty_breaks<-cty_map %>% filter(year=="Y2019") %>% select(density)
jbreaks<-getJenksBreaks(cty_breaks$density,6)
tmap_chain<-function(yr){
  maptitle<-paste("Density of ",chain_name," retailers, ",yr,sep="")
  filetitle<-paste("analysis_NO_UPLOAD/graphics/",gsub(" ","",chain_name),"map_",yr,".png",sep="")
  
  chainmap<-tm_shape(cty_map %>%
                        filter(year_num==yr))+
    tm_polygons("density",
                breaks=jbreaks,
                border.col="grey",
                border.alpha=0,
                palette="Greens",
                title="Stores per 100,000") +
    tm_shape(states)+
    tm_polygons(alpha=0)+
    tm_layout(title=maptitle,
              legend.outside=TRUE)+
    tm_credits("Data: USDA SNAP Retailers | Map by @jerry_shannon",
               position=c("RIGHT","BOTTOM"))
  tmap_save(chainmap,filetitle)
}

tmap_chain(2019)
years<-2008:2019
map(years,tmap_chain)

library(gifski)
files<-list.files("analysis_NO_UPLOAD/graphics/",pattern=substr(chain_name,1,4)) 
files<-paste("analysis_NO_UPLOAD/graphics/",files,sep="")
gifski(files,paste("analysis_NO_UPLOAD/graphics/",gsub(" ","",chain_name),"map",".gif",sep=""))


