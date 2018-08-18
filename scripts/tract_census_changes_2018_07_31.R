msa<-c("16980","19780","29820","41180")

tracts<-st_read("analysis_NO_UPLOAD/data/US_tractmsa_2016.gpkg") %>%
  select(gisjn_tct,GEOID,msa_fips) %>%
  mutate(msa_fips=as.character(msa_fips)) %>%
  filter(msa_fips %in% msa)
tracts_df<-tracts
st_geometry(tracts)<-NULL

tract_census<-read_csv("analysis_NO_UPLOAD/data/censusvars_tract_2018_06_17.csv") %>%
  left_join(tracts_df) %>%
  filter(msa_fips %in% msa)

tract_census_chg<-tract_census %>%
  filter(year %in% c("Y2010","Y2012")) %>%
  gather(totpop:noveh_pct,key="var",value="value") %>%
  spread(year,value) %>%
  filter(Y2010>0) %>%
  mutate(Y08_10_chg=round((Y2012-Y2010)/(Y2010),2),
         var_msaid=paste(var,msa_fips,sep="_"))

tract_census_sf<-tracts %>%
  right_join(tract_census_chg) %>%
  rename("geometry"=geom)

tract_write<-function(msaid_select) {
  filename_tct<-"analysis_NO_UPLOAD/data/tract_distances.gpkg"
  tractdata_select<-tract_census_sf %>%
    filter(var_msaid==msaid_select)
  st_write(tractdata_select,filename_tct,layer=msaid_select,update=TRUE,delete_layer=TRUE)
}

msaid_list<-tract_census_chg %>%
  select(var_msaid) %>%
  distinct()

map(msaid_list$var_msaid,tract_write)
