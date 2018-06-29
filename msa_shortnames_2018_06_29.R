#Develop short names for MSAs

library(tidyverse)
msa<-read_csv("data/snap_retailers.csv") %>%
  select(msa,msa_id) %>%
  filter(msa_id>0) %>%
  select(-msa_id) %>%
  distinct()

#State names
msa1<-msa$msa %>%
  str_split_fixed(",",2)
msa1<-as.data.frame(msa1)

msa2<-msa1$V2 %>%
  str_split_fixed("-",2)
msa2<-as.data.frame(msa2)

#City names
msa3<-msa1$V1 %>%
  str_split_fixed("-",2)
msa3<-as.data.frame(msa3)

msa_name<-bind_cols(msa3,msa2) %>%
  mutate(msa_name=paste(V1,V11,sep=", ")) %>%
  select(-V1:-V21)

msa_all<-bind_cols(msa,msa_name) %>%
  rename("msa_short"=msa_name)

write_csv(msa_all,"data/msa_shortname.csv")


##Join to store data
stores<-read_csv("data/snap_retailers.csv") %>%
  left_join(msa_all)
write_csv(stores,"data/snap_retailers.csv")
