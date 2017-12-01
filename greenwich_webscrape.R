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

#login, KEEP ON PERSONAL M: DRIVE, NOT PUBLIC 
source("D:/FME Scheduled_tasks/R_tasks/psma.R")

#rvest to locates form
url<-"https://www.ordnancesurvey.co.uk/orderdownload/orders"   ## page to spider
pgsession <-html_session(url)               ## create session
pgform <-html_form(pgsession)[[1]]       ## pull form from session

#fill and submit form
filled_form <- set_values(pgform, userid = username, password = password)
session1 <- submit_form(pgsession,filled_form)

#scrape the download list page
orderNumber <- html_nodes(session1, ".row0 td") %>% html_text()
updateDate <- html_node(session1, ".row0 td.sortColumn") %>% html_text()

orderNumber2 <- html_nodes(session1, ".row1 td") %>% html_text()
updateDate2 <- html_node(session1, ".row1 td.sortColumn") %>% html_text()

#order type and date match  SET THIS AFTER FINISHING : dmy(updateDate), or set Sys.Date()
if (stringr::str_detect(orderNumber[3], "Plus") && lubridate::dmy(updateDate) == Sys.Date()) { 
  link <- orderNumber[1] 
} else if (stringr::str_detect(orderNumber2[3], "Plus") && lubridate::dmy(updateDate) == Sys.Date()) {
  link <- orderNumber2[1]  
} else {
  print("no link")
}

#if ((stringr::str_detect(orderNumber[3], "Plus") && lubridate::dmy(updateDate) == Sys.Date())|
#    (stringr::str_detect(orderNumber2[3], "Plus") && lubridate::dmy(updateDate) == Sys.Date())) { 
  
  #follow first download link to first page
  #linkText1 <- session1 %>% 
  #  follow_link(i = 18) %>% ## this returns the first order, 20 = 3rd order, 19 = 2nd order, 18 = 1st order
  
  
  #follow first download link to first page
  linkText1 <- session1 %>% 
    jump_to(paste0("https://www.ordnancesurvey.co.uk/orderdownload/orders/", link ,"?")) %>% ## this returns the first order, 20 = 3rd order, 19 = 2nd order, 18 = 1st order
    html_node("#orderLinks") %>% # which line to pull text from, all the file names
    html_text() # turn into readable text  
  
  #html raw text to vector of files to download
  linkText2 <- stringr::str_split(linkText1, '[\r\n\t]')
  linkText3 <- unlist(linkText2)
  linkText4 <- linkText3[linkText3 != ""]
  linkText4 <- gsub(" ", "", linkText4)
  linkText4 <- linkText4[linkText4 != ""]
  linkText4 <- gsub("-", "_", linkText4)
  
  #download all the <li> items
  #use linkText4 with an lapply function 
  #follow first download link to first page
  download1 <- session1 %>% 
    jump_to(paste0("https://www.ordnancesurvey.co.uk/orderdownload/orders/", link ,"?")) %>% ## 20 = 3rd order, 19 = 2nd order, 18 = 1st order
    html_nodes("a") %>%  #link nodes
    html_attr("href") #attributes with a hyperlink
  
  download2 <- download1[nchar(download1) > 250] #correct type of hypertext, short ones are ignored
  download3 <- download2[!is.na(download2)]
  
  # test to see if a folder exists for today's date CAN BE DELETED
  today <- format(Sys.time(), "%Y%m")
  
  # test if folder exists, if not create a directory of today without hyphens, setwd to new folder
  if(dir.exists(today)){
    print("stopping")
    quit() 
  } else {
    print("need to create folder")
    dir.create(today)  
  }
  
  #download all zip files from the links
  for (i in 1:length(linkText4)) {
    curl_download(download3[i], destfile = linkText4[i])
  }
  