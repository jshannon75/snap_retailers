library(tidyverse)
library(sf)

cty_extension<-st_read("C:/Users/jshannon/Dropbox/Jschool/Research/SNAP_and_SNAP_Ed/SNAPEd_projects/data/state offices/Extension/County_extension_districts.shp") %>%
  select(GEOID,Ext_Dist) %>%
  rename(cty_fips=GEOID) %>%
  st_set_geometry(NULL)

rural_urb<-readxl::read_xls("data/ruralurbancodes2013.xls") %>%
  rename(cty_fips=FIPS) %>%
  select(cty_fips,RUCC_2013) %>%
  mutate(urb_class=case_when(RUCC_2013 %in% c(1,2,3)~"Metro",
                             RUCC_2013 %in% c(4,5)~"Non-metro, population of >20K",
                             RUCC_2013 %in% c(6,7,8,9)~"Non-metro, population of <20K"))

snap_retail<-st_read("analysis_NO_UPLOAD/data/snap_retailers_full.gpkg")

snap_retail_long<-snap_retail %>%
  filter(st_fips=="13") %>%
  left_join(cty_extension) %>%
  left_join(rural_urb) %>%
  st_set_geometry(NULL) %>%
  pivot_longer(Y2005:Y2020,names_to="year",values_to="dummy") %>%
  filter(dummy==1 & year %in% c("Y2005","Y2010","Y2015","Y2020")) %>%
  filter(store_group %in% c("Local foods","Supermarket","Small retail")) %>%
  mutate(store_group=if_else(str_detect(tolower(store_name),"dollar deneral|dollar tree|family dollar"),
                             "Dollar store",store_group))

snap_retail_rucctbl<-snap_retail_long %>%
  count(urb_class,year,store_group) %>%
  pivot_wider(names_from=year,values_from=n,values_fill=0) %>%
  filter(is.na(store_group)==FALSE)

snap_retail_exttbl<-snap_retail_long %>%
  count(Ext_Dist,year,store_group) %>%
  pivot_wider(names_from=year,values_from=n,values_fill=0) %>%
  filter(is.na(store_group)==FALSE)

snap_retail_all<-snap_retail_long %>%
  count(Ext_Dist,urb_class,year,store_group) %>%
  pivot_wider(names_from=year,values_from=n,values_fill=0) %>%
  filter(is.na(store_group)==FALSE)

write_csv(snap_retail_all,"data/snap_retailcount_gacty_2021_09_13.csv")

##LILA populations
lila<-readxl::read_xlsx("data/FoodAccessResearchAtlasData2019.xlsx",sheet=3) %>%
  filter(State=="Georgia")

popdata<-tidycensus::get_acs(state="Georgia",geography="tract",variables = "B01001_001") %>%
  filter(estimate>0) %>%
  rename(CensusTract=GEOID) %>%
  select(-NAME,-variable,-moe) %>%
  rename(pop2019=estimate)

lila_tbl<-lila %>%
  left_join(popdata) %>%
  mutate(cty_fips=substr(CensusTract,1,5)) %>%
  left_join(cty_extension) %>%
  left_join(rural_urb) %>%
  group_by(Ext_Dist,urb_class,LILATracts_1And10) %>%
  summarise(pop=sum(pop2019,na.rm=TRUE)) %>%
  pivot_wider(names_from=LILATracts_1And10,values_from=pop) %>%
  mutate(total_pop=`0`+`1`,
         pct_lila=round(`1`/total_pop*100,1))

write_csv(lila_tbl,"data/lila_table_ga_2021_09_13.csv")
