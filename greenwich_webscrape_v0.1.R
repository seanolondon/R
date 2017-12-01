#automation webscrape of the greenwich new buildings site
#Run in 64 bit to do arcgis binding with armap pto

#clear all variables
rm(list=ls())

library(httr, lib = "C:/Program Files/R/R-3.4.1/library")
library(rvest,lib = "C:/Program Files/R/R-3.4.1/library")
library(XML, lib = "C:/Program Files/R/R-3.4.1/library")
library(magrittr,lib = "C:/Program Files/R/R-3.4.1/library")
library(multiplex,lib = "C:/Program Files/R/R-3.4.1/library")
library(rgdal,lib = "C:/Program Files/R/R-3.4.1/library")
library(data.table,lib = "C:/Program Files/R/R-3.4.1/library")
library(dplyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(tidyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(RCurl,lib = "C:/Program Files/R/R-3.4.1/library")
library(curl,lib = "C:/Program Files/R/R-3.4.1/library")
library(RPostgreSQL, lib = "C:/Program Files/R/R-3.4.1/library")
library(rpostgis, lib = "C:/Program Files/R/R-3.4.1/library")
library(arcgisbinding, lib = "C:/Program Files/R/R-3.4.1/library")
arc.check_product()

#setwd
setwd("D:/FME Scheduled_tasks/R_tasks/")

#rvest to locates form
url<-"https://planning.royalgreenwich.gov.uk/online-applications/search.do?action=monthlyList"   ## page to spider
session <-html_session(url) 
## create session
greenwhichForm <-html_form(session)[[1]]

#which month to query
month <- "Nov 17"
parish <- "GRN"

greenwhichForm <- set_values(greenwhichForm, searchCriteria.parish = parish, month = month, dateType = "DC_Decided")
session1 <- submit_form(session,greenwhichForm)

#scrape the download list page
#orderNumber <- html_nodes(session1, "li") %>% html_text()
#orderNumber[21]

link <- session1 %>% html_nodes(xpath = paste0('//*[@id="searchresults"]/li[',1,']/a')) %>% html_text()

table <- session1 %>% 
  follow_link(link) %>%
  read_html() %>% 
  html_table() %>%
  as.data.frame()

wideTable <- table %>%
  spread(X1,X2)


linkCount <- length(session1 %>% html_nodes(xpath = '//*[@id="searchresults"]/li/a') %>% html_text())


for (i in 1:linkCount) {
link <- session1 %>% html_nodes(xpath = paste0('//*[@id="searchresults"]/li[',i,']/a')) %>% html_text()

table1 <- session1 %>% 
            follow_link(link) %>%
            read_html() %>% 
            html_table() %>%
            as.data.frame()

table2 <- session1 %>% 
            follow_link(link) %>%
            follow_link("Further Information") %>%
            read_html() %>% 
            html_table() %>%
            as.data.frame()

table3 <- bind_rows(table1, table2) %>% 
          distinct()

wideTable <- table3 %>%
              spread(X1,X2) %>%
              bind_rows(wideTable)

}

uniqueRefWideTable <- distinct(wideTable, Reference, .keep_all = TRUE)  

