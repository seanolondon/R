#Automation of Ordnance Survey data from the Public Sector Mapping Agreement (PSMA)

#Download update of OS MasterMap Topography Layer - 5km

#clear all variables
rm(list=ls())

#httr for login
library(httr)

#rvest for web scraping 
library(rvest)

#XML for reading the page.
library(XML)

#magrittr for navigating ndoes easier
library(magrittr)

#use to match str
library(stringr)

#setwd

## test to see if a folder exists for today's date CAN BE DELETED
#today <- Sys.Date()
#today2 <- gsub("-","",today)
#dir.exists(today2)

## test if folder exists, if not create a directory of today without hypens, setwd to new folder
#if(!dir.exists(today2))
#{dir.create(today2)}
#setwd(today2)

#login as paul
source("M:/ProgrammingScripts/R/pwords/psma.R")
#osLoginUrl <- GET("https://www.ordnancesurvey.co.uk/sso/login.shtml", authenticate(username, password))

#using rvest to locate form on page
url<-"https://www.ordnancesurvey.co.uk/orderdownload/orders"   ## page to spider
pgsession <-html_session(url)               ## create session
pgform <-html_form(pgsession)[[1]]       ## pull form from session

#fill and submit form
filled_form <- set_values(pgform, userid = username, password = password)
submit_form(pgsession,filled_form)
is.session(pgsession)

#scrape the download list page

table1 <- html_node(pgsession, ".row0 td")
table2 <-html_text(table1)
orderNumber <- table2[1]

#use the order number for master map to get the ownload webpage
# (use an if statement to expand the code to get everything)
downloadPage <- rvest::html(paste0("https://www.ordnancesurvey.co.uk/orderdownload/orders/",orderNumber,"?"))
downloadPage %>% html_text(html_node(downloadPage, ".pageContent"))

#download all the <li> items

#download into correct folder

#merge/put together... further processing

#schedule in Jenkins 

