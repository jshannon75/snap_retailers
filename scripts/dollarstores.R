library(tidyverse)
library(sf)
library(gganimate)
library(tmap)

stores<-st_read("analysis_NO_UPLOAD/data/snap_retailers_full.gpkg")

dollars<-stores %>%
  mutate(store_name_l=tolower(store_name),
         store=case_when(grepl("family dollar",store_name_l,fixed=TRUE)~"Family Dollar",
                         grepl("dollar tree",store_name_l,fixed=TRUE)~"Dollar Tree",
                         grepl("dollar general",store_name_l,fixed=TRUE)~"Dollar General")) %>%
  filter(is.na(store)==FALSE) %>%
  gather(Y2008:Y2019,key="year",value="pres") %>%
  mutate(year_num=as.numeric(substr(year,2,5)),
         time=paste(year_num,"-06-01",sep="")) %>%
  filter(pres==1)


dollars_wide<-dollars %>% 
  select(-time,-year_num) %>%
  spread(year,pres,fill=0)
st_write(dollars_wide,"data/dollars_all.gpkg")
write_csv(dollars %>% st_set_geometry(NULL),"data/dollars_all_long.csv")

dollars_st<-dollars %>%
  filter(state %in% c("LA","AR","KY","TN","AL","MS","GA","FL","NC","SC"))
  #filter(state!="HI" & state!="AK" & X<0)
  
dollars_sf<-st_as_sf(dollars_st,coords=c("X","Y"),crs=4326,remove=FALSE) %>%
  st_transform(102003)

anim<-tm_shape(counties)+
  tm_borders(col="grey",alpha=0.3)+
#tm_shape(states)+
#  tm_borders(alpha=0.9,lwd=1.2)+
tm_shape(dollars_sf)+
  tm_dots(size=0.04,
          alpha=0.6,
          col="store",
          palette=c("#edbb25","#003791","#910000"))+
  tm_layout(legend.outside=TRUE,legend.title.size=0.1)+
  tm_facets(along="year_num", free.coords=FALSE)
tmap_animation(anim, 
               filename = "dollgen_se_animation.gif",
               width = 1500, height = 900, delay = 150)

#Old approach with gganimate
# p<-ggplot(dollars_sf) +
#   geom_sf(aes(color=store))+
#   geom_sf(data=counties,aes(alpha=0.6,fill=NA))+
#   theme_minimal()+
#   theme(plot.title = element_text(hjust = 0.5))+
#   transition_states(year_num,0,8) +
#   enter_appear(early=FALSE)+
#   exit_disappear()+
#   labs(title = 'Year: {closest_state}')
# animate(p,nframes=11,fps=1)  