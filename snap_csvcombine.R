library(readxl)
library(tidyverse)

# Create a vector of Excel files to read
files.to.read = list.files("data",pattern="xlsx")


allstoredata<-lapply(files.to.read, function(f) {
  f1<-paste("data/",f,sep="")
  df<-read_excel(f1)[-1,1:10] 
  names(df)<-c("date","store_name","addr_num","addr_st","addr_add","city","st","zip5","zip4","store_type")
  df<-df %>%
    select(-date,-zip4) %>%
    mutate(date=substr(f,13,20))
  }) %>% 
  bind_rows() 

#Filter for unique store names and street address and zip. Remove duplicates.
allstoredata_filter<-allstoredata %>%
  select(store_name,addr_num,addr_st,city)
allstoredata_filter<-unique(allstoredata_filter)
allstoredata_filter<-allstoredata_filter %>%
  mutate(id_num=seq(1:nrow(allstoredata_filter)),
         storeid=sprintf("st_%06d", id_num)) %>%
  select(-id_num)
allstoredata_id<-left_join(allstoredata,allstoredata_filter)
allstoredata_id<-unique(allstoredata_id)

#Create year columns
allstoredata_years<-allstoredata_id %>%
  mutate(dummy=1) %>%
  spread(date,dummy) 
names(allstoredata_years)<-c("store_name","addr_num","addr_st","addr_add","city","st","zip5","store_type",
                             "storeid","Y2008","Y2009","Y2010","Y2011","Y2012","Y2013","Y2014","Y2015","Y2016","Y2017")
temp<-allstoredata_years %>% select(Y2008:Y2017)
temp[is.na(temp)]<-0
temp1<-allstoredata_years %>% select(store_name:storeid)
allstoredata_years<-cbind(temp1,temp)

#Add in lat long
storexy<-read_excel("data/Auth Stores 06-30-17.xlsx")[-1,] 
names(storexy)<-c("date","store_name","addr_num","addr_st","addr_add","city","st","zip5","zip4","store_type","long","lat")
storexy<-storexy %>% 
  select(store_name,addr_num,addr_st,city,long,lat)
allstoredata_xy<-full_join(allstoredata_years,storexy)

#Remove duplicate records
allstoredata_xy<-unique(allstoredata_xy)

write_csv(allstoredata_xy,"snap_retailers_natl_2018_01_03.csv")

#Create basic histogram by store type and year
allstoredata_table<-allstoredata_xy %>%
  gather(Y2008:Y2017,key="year",value="count") %>%
  group_by(store_type,year) %>% 
  summarise(store_count=sum(count)) %>%
  filter(store_type!="NA")

ggplot(allstoredata_table,aes(x=year,y=store_count)) + 
  geom_bar(stat="identity",fill="#f03b20") +
  facet_wrap(~store_type,scales="free_y",nrow=6,ncol=3) + 
  theme_minimal()+
  xlab("Year")+
  ylab("Store count")+
  theme(axis.text.x=element_text(angle=45,vjust=0.5))


##Identify duplicate addresses only--this removes stores with only street names and where stores reopen after closing. 
#Create list of unique addresses
storedata_addressonly<-allstoredata_xy %>%
  group_by(addr_num,addr_st,city) %>%
  summarise() 

storedata_addressonly$addr_id<-seq(nrow(storedata_addressonly))

allstoredata_id2<-left_join(allstoredata_xy,storedata_addressonly) 

#Count number of stores with same address
allstoredata_idcnt<-allstoredata_id2 %>%
  group_by(addr_id) %>%
  summarise(record_cnt=n())

allstoredata_id3<-left_join(allstoredata_id2,allstoredata_idcnt)

write_csv(allstoredata_id3,"snap_retailers_dupadd_2018_01_03.csv")
