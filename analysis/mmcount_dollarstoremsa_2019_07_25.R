library(tidyverse)

tractdata<-read_csv("analysis_NO_UPLOAD/dollar store cities paper/data/modeldata_cat_2019_06_20.csv") %>%
  select(gisjn_tct) %>%
  distinct()

mmclass<-read_csv("analysis_NO_UPLOAD/dollar store cities paper/data/ustracts_mm_acs_10_17.csv") %>%
  rename(gisjn_tct=GISJOIN) %>%
  inner_join(tractdata)

classcount<-mmclass %>%
  ungroup() %>%
  count(class_mm_char,year) %>%
  spread(year,n)

write_csv(classcount,"analysis_NO_UPLOAD/dollar store cities paper/data/classcount_msa_2019_07_25.csv")

##How many classes did tracts have?

census_data_summary<-mmclass %>%
  ungroup() %>%
  count(gisjn_tct,class_mm) %>%
  count(gisjn_tct)

table(census_data_summary$n)

#Create a tract change classification

p <- function(v) {
  Reduce(f=paste0, x = v)
}

class_msa<-mmclass %>%
  select(gisjn_tct,class_mm,year) %>%
  group_by(gisjn_tct,class_mm) %>%
  summarise(year=first(year)) %>% 
  mutate(class_mm1=paste(class_mm,"_",sep="")) %>%
  ungroup() %>%
  select(-year) %>%
  group_by(gisjn_tct) %>%
  summarise(class_group=p(as.character(class_mm1))) %>%
  mutate(class_group=substr(class_group,1,nchar(class_group)-1))

class_msa_cnt<-class_msa %>%
  count(class_group)

write_csv(class_msa,"analysis_NO_UPLOAD/dollar store cities paper/data/classmm_10_17.csv")
write_csv(class_msa_cnt,"analysis_NO_UPLOAD/dollar store cities paper/data/classmm_table_10_17.csv")

##Data is categorized

##Read in categories and tie to tracts
class_msa_cat<-read_csv("analysis_NO_UPLOAD/dollar store cities paper/data/classmm_table_10_17_cat.csv") %>%
  select(-n)

class_msa_cat1<-class_msa %>%
  left_join(class_msa_cat)

write_csv(class_msa_cat1,"analysis_NO_UPLOAD/dollar store cities paper/data/classmm_timecat_10_17.csv")

table(class_msa_cat1$class_grp_cat)
