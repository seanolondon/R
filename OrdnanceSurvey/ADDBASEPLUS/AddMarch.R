#Automation of Ordnance Survey data from the Public Sector Mapping Agreement (PSMA)
#Run in 64 bit to do arcgis binding with armap pto

#clear all variables
rm(list=ls())
if(file.exists("D:/FME Scheduled_tasks/R_tasks/abaseplus_automation_v0.9_log.txt"))
{file.remove("D:/FME Scheduled_tasks/R_tasks/abaseplus_automation_v0.9_log.txt")}

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

#order type and date match  SET THIS AFTER FINISHING : dmy(updateDate)
#if (stringr::str_detect(orderNumber[3], "Plus") && lubridate::dmy(updateDate) == Sys.Date()) {
session2 <- jump_to(session1, url = "https://www.ordnancesurvey.co.uk/orderdownload/orders?id=&idH=&idE=&size=10&filter=0&sort=8&page=2")

#follow first download link to first page
linkText1 <- session2 %>% 
  follow_link(i = 19) %>% ## this returns the first order, 20 = 3rd order, 19 = 2nd order, 18 = 1st order
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
download1 <- session2 %>% 
  follow_link(i = 19) %>% ## 20 = 3rd order, 19 = 2nd order, 18 = 1st order
  html_nodes("a") %>%  #link nodes
  html_attr("href") #attributes with a hyperlink

download2 <- download1[nchar(download1) > 250] #correct type of hypertext, short ones are ignored
download3 <- download2[!is.na(download2)]

# test to see if a folder exists for today's date CAN BE DELETED
#today <- format(Sys.time(), "%Y%m")
today <- ("201703")
dir.exists(today)

# test if folder exists, if not create a directory of today without hyphens, setwd to new folder
if(!dir.exists(today))
{dir.create(today)}

#download all zip files from the links
for (i in 1:length(linkText4)) {
  curl_download(download3[i], destfile = linkText4[i])
}

cpdir <- paste0("D:/FME Scheduled_tasks/R_tasks/")
files <- dir(path = cpdir, pattern = "zip")

for (i in 1:length(files)) {
  unzip(files[i])
}

rm(files)
filesCSV <- dir(path = cpdir, pattern = "csv")

adbaseReader <- function(x) {
  fread(x, header=FALSE, colClasses = "character") %>%
    format(scientific=FALSE)
}

addBaseMerge <- do.call("rbind",lapply(filesCSV, adbaseReader)) %>%
  as.data.frame()

#reformat the field names
newFieldNames <- read.table("newfieldnames.txt")
addBaseMerge2 <- setnames(addBaseMerge, old = names(addBaseMerge), new = as.vector(newFieldNames$V1))
addBaseMerge2$OBJECTID <- as.character(addBaseMerge$UPRN)
addBaseMerge$UPRN <- as.character(addBaseMerge$UPRN)
addBaseMerge2$UPRN <- stringr::str_pad(addBaseMerge$UPRN, width = 12, "left", pad = 0)
addBaseMerge2$PARENT_UPRN <-  stringr::str_pad(addBaseMerge$PARENT_UPRN, width = 12, "left", pad = 0)
addBaseMerge2$X_COORDINATE <- round(as.numeric(as.character(addBaseMerge2$X_COORDINATE)), digits = 2)
addBaseMerge2$Y_COORDINATE <- round(as.numeric(as.character(addBaseMerge2$Y_COORDINATE)), digits = 2)


##add the flat check
addBaseMerge2 <- addBaseMerge2 %>%
  mutate(XY = paste0(X_COORDINATE, Y_COORDINATE)) %>%
  add_count(XY) %>%
  subset(select=-XY) %>%
  rename(FLAT = n)

#add group layer for batch writing
addBaseMerge2 <- mutate(addBaseMerge2, group = ceiling(as.numeric(rownames(addBaseMerge2))/100000))

print("write csv")
writeFile <- paste0("D:/FME Scheduled_tasks/R_tasks/",today,"/address_base_london_",today,".csv")
fwrite(addBaseMerge2, writeFile, append = FALSE, verbose = TRUE)

###R spatial####

# plot xy
print("start spatial")
codecoords <- subset(addBaseMerge2, select = c("X_COORDINATE", "Y_COORDINATE"))
codecoords$X_COORDINATE <- as.numeric(as.character(codecoords$X_COORDINATE))
codecoords$Y_COORDINATE <- as.numeric(as.character(codecoords$Y_COORDINATE))
names(codecoords) <- tolower(names(codecoords))
names(addBaseMerge2) <- tolower(names(addBaseMerge2))

#clip to london (new data frame)
addBaseMerge3 <- SpatialPointsDataFrame(codecoords, data = addBaseMerge2, proj4string = CRS("+init=epsg:27700"))
londonOutline <- readOGR("London_GLA_Boundary.shp", "London_GLA_Boundary",verbose=F,stringsAsFactors = F)

addBaseMerge3BNG <- spTransform(addBaseMerge3, CRS(proj4string(londonOutline)))
#londonOutline <- spTransform(londonOutline, CRS("+init=epsg:27700"))
addBaseMerge3BNGLDN <- addBaseMerge3BNG[londonOutline, ]

#installed arcgis binding and running on arcgis pro, in geoprocessing options in pro had to set home directory for R

rm(addBaseMerge2)
rm(addBaseMerge)
print("start arc")
arc.check_product()
arcgisbinding::arc.write(addBaseMerge3BNGLDN, path = paste0("abp.gdb/addressBasePlusLondon_",today))

arc.check_product()
arcgisbinding::arc.write(addBaseMerge3BNG, path = paste0("abp.gdb/addressBasePlus_",today))
print("finish arc")

#CLEANUP TEMP FILES
finalCSV <- list.files(pattern = "csv")
finalZIP <- list.files(pattern = "zip")

for (i in 1:length(finalCSV)){
  if (file.exists(finalCSV[i])) file.remove(finalCSV[i])
} 

for (i in 1:length(finalZIP)){
  if (file.exists(finalZIP[i])) file.remove(finalZIP[i])
} 
print("success")