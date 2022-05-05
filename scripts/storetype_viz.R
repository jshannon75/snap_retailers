#Store subgroups
library(tidyverse)
library(sf)
library(extrafont)
library(scales)

windowsFonts()

retail<-read_csv("data/hist_snap_retailer_final2021.csv") %>%
  mutate(store_lower=tolower(store_name))

#Overall trend--Need to create dummy variables
retail_dummies<-retail %>%
  mutate(end_year=if_else(is.na(end_year),2050,end_year),
         `2000`=if_else(auth_year<=2000 & end_year>2000,1,0),
         `2001`=if_else(auth_year<=2001 & end_year>2001,1,0),
         `2002`=if_else(auth_year<=2002 & end_year>2002,1,0),
         `2003`=if_else(auth_year<=2003 & end_year>2003,1,0),
         `2004`=if_else(auth_year<=2004 & end_year>2004,1,0),
         `2005`=if_else(auth_year<=2005 & end_year>2005,1,0),
         `2006`=if_else(auth_year<=2006 & end_year>2006,1,0),
         `2007`=if_else(auth_year<=2007 & end_year>2007,1,0),
         `2008`=if_else(auth_year<=2008 & end_year>2008,1,0),
         `2009`=if_else(auth_year<=2009 & end_year>2009,1,0),
         `2010`=if_else(auth_year<=2010 & end_year>2010,1,0),
         `2011`=if_else(auth_year<=2011 & end_year>2011,1,0),
         `2012`=if_else(auth_year<=2012 & end_year>2012,1,0),
         `2013`=if_else(auth_year<=2013 & end_year>2013,1,0),
         `2014`=if_else(auth_year<=2014 & end_year>2014,1,0),
         `2015`=if_else(auth_year<=2015 & end_year>2015,1,0),
         `2016`=if_else(auth_year<=2016 & end_year>2016,1,0),
         `2017`=if_else(auth_year<=2017 & end_year>2017,1,0),
         `2018`=if_else(auth_year<=2018 & end_year>2018,1,0),
         `2019`=if_else(auth_year<=2019 & end_year>2019,1,0),
         `2020`=if_else(auth_year<=2020 & end_year>2020,1,0),
         `2021`=if_else(auth_year<=2021 & end_year>2021,1,0))

inspect<-retail_dummies[1:200,]

retail_table<-retail_dummies %>%
  select(record_id,store_group,`2000`:`2021`) %>%
  pivot_longer(`2000`:`2021`,names_to="year",values_to="dummy") %>%
  group_by(store_group,year) %>%
  summarize(count=sum(dummy)) %>%
  rename(`Store type`=store_group)

ggplot(retail_table,aes(x=year,y=count,fill=`Store type`))+
  geom_bar(stat="identity")+
  scale_fill_brewer(palette="Set3")+
  scale_y_continuous(labels = comma)+
  ggtitle("Count of SNAP authorized retailers since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"),
        axis.text.x=element_text(angle=45,hjust=1))+
  xlab("Year")+ylab("Count")+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/allretailers.jpeg")

#Dollar stores
dollar_keys<-c("dollar general","dollar tree","family dollar","99 cent")

dollars<-retail %>%
  filter(str_detect(store_lower, paste(dollar_keys, collapse = "|"))) %>%
  mutate(dollar_type=case_when(str_detect(store_lower,"dollar general")~"Dollar General",
                        str_detect(store_lower,"dollar tree")~"Dollar Tree",
                        str_detect(store_lower,"family dollar")~"Family Dollar",
                        TRUE~"Other")) %>%
  select(-store_lower) 

write_csv(dollars,"data/dollars.csv")

ggplot(dollars %>% 
         filter(auth_year>1999) %>% 
         mutate(auth_year=as.character(auth_year)) %>%
         rename(`Retail chain`=dollar_type),
       aes(x=auth_year,fill=`Retail chain`))+
  geom_bar() +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("New SNAP authorizations for dollar and 99-cent stores since 2000") +
  scale_fill_manual(values=c("#cec548","#00963A","#EF2F25","grey"))+
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"),
        axis.text.x=element_text(angle=45,hjust=1)) +
  facet_wrap(~`Retail chain`,scales="free")+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/dollar_authchg2021.jpeg",width=10,height=5)

ggplot(dollars %>% 
         filter(end_year>1999) %>% 
         mutate(end_year=as.character(auth_year)) %>%
         rename(`Retail chain`=dollar_type),
       aes(x=end_year,fill=`Retail chain`))+
  geom_bar() +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("SNAP de-authorizations for dollar and 99-cent stores since 2000") +
  scale_fill_manual(values=c("#cec548","#00963A","#EF2F25","grey"))+
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"),
        axis.text.x=element_text(angle=45,hjust=1)) +
  facet_wrap(~`Retail chain`,scales="free")+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/dollar_endchg2021.jpeg",width=10,height=5)

#Supermarkets and Grocers
supers<-retail %>%
  filter(store_group=="Supermarket")%>%
  select(-store_lower)

write_csv(supers,"data/supermarkets.csv")

ggplot(supers %>% filter(auth_year>1999) %>% mutate(auth_year=as.character(auth_year)),
       aes(x=auth_year))+
  geom_bar(fill="#9b5445") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("New SNAP authorization for supermarkets since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/supermarket_authchg2021.jpeg")

ggplot(supers %>% filter(end_year>1999) %>% mutate(auth_year=as.character(end_year)),
       aes(x=end_year))+
  geom_bar(fill="#9b5445") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("SNAP de-authorizations for supermarkets since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/supermarket_endchg2021.jpeg")

grocers<-retail %>%
  filter(store_group=="Grocer")%>%
  select(-store_lower)

write_csv(grocers,"data/grocers.csv")

ggplot(grocers %>% filter(auth_year>1999) %>% mutate(auth_year=as.character(auth_year)),
       aes(x=auth_year))+
  geom_bar(fill="#9b5445") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("New SNAP authorization for grocers since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/grocers_authchg2021.jpeg")

ggplot(grocers %>% filter(end_year>1999) %>% mutate(auth_year=as.character(end_year)),
       aes(x=end_year))+
  geom_bar(fill="#9b5445") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("SNAP de-authorizations for grocers since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/grocers_endchg2021.jpeg")

#Walmart
walmart<-retail %>%
  filter(str_detect(store_lower,"walmart | wal-mart")) %>%
  select(-store_lower)
write_csv(walmart,"data/walmarts.csv")

ggplot(walmart %>% filter(auth_year>1999) %>% mutate(auth_year=as.character(auth_year)),
       aes(x=auth_year))+
  geom_bar(fill="#004F9A") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("New SNAP authorization for Walmarts since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/walmart_authchg2021.jpeg")

ggplot(walmart %>% filter(end_year>1999) %>% mutate(end_year=as.character(end_year)),
       aes(x=end_year))+
  geom_bar(fill="#004F9A") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("SNAP de-authorizations for Walmarts since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/walmart_endchg2021.jpeg")

#Local foods
local<-retail %>%
  filter(store_group=="Local foods") 
write_csv(local,"data/localfoods.csv")

ggplot(local %>% filter(auth_year>1999) %>% mutate(auth_year=as.character(auth_year)),
       aes(x=auth_year))+
  geom_bar(fill="#4c6d5c") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("New SNAP authorization for local food retailers since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/local_authchg2021.jpeg")

ggplot(local %>% filter(end_year>1999) %>% mutate(end_year=as.character(end_year)),
       aes(x=end_year))+
  geom_bar(fill="#4c6d5c") +
  xlab("Authorization year")+ylab("Count") +
  ggtitle("SNAP de-authorizations for local food retailers since 2000") +
  theme_minimal()+
  theme(text=element_text(family="Gill Sans MT"))+
  labs(caption="Data source: https://github.com/jshannon75/snap_retailers")
ggsave("graphics/local_endchg2021.jpeg")
