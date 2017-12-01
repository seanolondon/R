#Automation of Ordnance Survey data from the Public Sector Mapping Agreement (PSMA)
#Run in 32 bit to do arcgis binding

#clear all variables
rm(list=ls())
if(file.exists("D:/FME Scheduled_tasks/R_tasks/abaseplus_automation_v0.9_log.txt"))
{file.remove("D:/FME Scheduled_tasks/R_tasks/abaseplus_automation_v0.9_log.txt")}

#for web nav
library(httr, lib = "C:/Program Files/R/R-3.4.1/library")
#web forms
library(rvest,lib = "C:/Program Files/R/R-3.4.1/library")
library(XML, lib = "C:/Program Files/R/R-3.4.1/library")
#for piping
library(magrittr,lib = "C:/Program Files/R/R-3.4.1/library")
#library(stringr,lib = "C:/Program Files/R/R-3.4.1/library")
#library(lubridate,lib = "C:/Program Files/R/R-3.4.1/library")
#to read gml
library(multiplex,lib = "C:/Program Files/R/R-3.4.1/library")
library(rgdal,lib = "C:/Program Files/R/R-3.4.1/library")
library(data.table,lib = "C:/Program Files/R/R-3.4.1/library")
library(dplyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(tidyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(RCurl,lib = "C:/Program Files/R/R-3.4.1/library")
library(curl,lib = "C:/Program Files/R/R-3.4.1/library")
library(RPostgreSQL, lib = "C:/Program Files/R/R-3.4.1/library")
library(rpostgis, lib = "C:/Program Files/R/R-3.4.1/library")
library(RODBC, lib = "C:/Program Files/R/R-3.4.1/library")

#setwd
#setwd("Q:\\Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\AddressBase_Plus")
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
#if (stringr::str_detect(orderNumber[3], "Plus") && lubridate::dmy("5 July 2017") == Sys.Date()) {


#follow first download link to first page
linkText1 <- session1 %>% 
  follow_link(i = 19) %>% ## this returns the first order, 20 = 3rd order, 19 = 2nd order, 18 = 1st order
  html_node("#orderLinks") %>% # which line to pull text from, all the file names
  html_text() # turn into readable text

#html raw text to vector of files to download
linkText2 <- stringr::str_split(linkText1, '[\r\n\t]')
linkText3 <- unlist(linkText2)
linkText4 <- linkText3[linkText3 != ""]
linkText4 <- gsub(" ", "_", linkText4)
linkText4 <- gsub("-", "_", linkText4)

#download all the <li> items
#use linkText4 with an lapply function 
#follow first download link to first page
download1 <- session1 %>% 
  follow_link(i = 19) %>% ## 20 = 3rd order, 19 = 2nd order, 18 = 1st order
  html_nodes("a") %>%  #link nodes
  html_attr("href") #attributes with a hyperlink

download2 <- download1[nchar(download1) > 250] #correct type of hypertext, short ones are ignored
download3 <- download2[!is.na(download2)]

# test to see if a folder exists for today's date CAN BE DELETED
today <- format(Sys.time(), "%Y%m")
dir.exists(today)


# test if folder exists, if not create a directory of today without hyphens, setwd to new folder
if(!dir.exists(today))
{dir.create(today)}
#setwd(today)

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
    #fread removing scientific format
    fread(x, header=FALSE, colClasses = "character") %>%
    format(scientific=FALSE)
}

addBaseMerge <- do.call("rbind",lapply(filesCSV, adbaseReader)) %>%
  as.data.frame()

#reformat the field names
newFieldNames <- read.table("newfieldnames.txt")
addBaseMerge2 <- setnames(addBaseMerge, old = names(addBaseMerge), new = as.vector(newFieldNames$V1))
addBaseMerge2$OBJECTID <- addBaseMerge$UPRN
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

writeFile <- paste0("D:/FME Scheduled_tasks/R_tasks/",today,"/address_base_london_",today,".csv")
fwrite(addBaseMerge2, writeFile)

###R spatial####

# plot xy
#addBaseMerge2 <- fread(writeFile)

codecoords <- subset(addBaseMerge2, select = c("X_COORDINATE", "Y_COORDINATE"))
codecoords$X_COORDINATE <- as.numeric(as.character(codecoords$X_COORDINATE))
codecoords$Y_COORDINATE <- as.numeric(as.character(codecoords$Y_COORDINATE))
names(codecoords) <- tolower(names(codecoords))
names(addBaseMerge2) <- tolower(names(addBaseMerge2))
#attr(addBaseMerge2,"row.names") <- as.character(addBaseMerge2[,1])
#addBaseMerge2 <- tibble::column_to_rownames(addBaseMerge2, var="objectid")
addBaseMerge3 <- SpatialPointsDataFrame(codecoords, data = addBaseMerge2, proj4string = CRS("+init=epsg:27700"))
#clean up 
#rm(addBaseMerge2)
#rm(addBaseMerge)

#clip to london (new data frame)
addBaseMerge3BNG <- spTransform(addBaseMerge3, CRS("+init=epsg:27700"))

londonOutline <- readOGR("London_GLA_Boundary.shp", "London_GLA_Boundary") 
londonOutline <- spTransform(londonOutline, CRS(proj4string(addBaseMerge3BNG)))

#clean up 
rm(list=setdiff(ls(), c("addBaseMerge3BNG", "londonOutline")))

#write to postgres (Clipped & Unclipped)
conn <- dbConnect("PostgreSQL",dbname='gis',host='gispostgres.cfbgjjkrhbvr.eu-west-1.rds.amazonaws.com',port='5432',user='gisapdata',password='gi$own')

# 2 subsets
addBaseMerge3BNG1 <- addBaseMerge3BNG[1:(nrow(addBaseMerge3BNG)/2),]
addBaseMerge3BNG2 <- addBaseMerge3BNG[(nrow(addBaseMerge3BNG)/2):nrow(addBaseMerge3BNG),]

rm(addBaseMerge3BNG)
#dbDrop(conn, name = c("gisapdata", "addbase"), type = "table")
system.time(
pgInsert(conn, name = c("gisapdata", "addbase"), data.obj = addBaseMerge3BNG1, geom = "geom", overwrite = FALSE)
)
pgInsert(conn, name = c("gisapdata", "addbase"), data.obj = addBaseMerge3BNG2, geom = "geom", overwrite = FALSE)
system.time(
  pgInsert(conn, name = c("gisapdata", "addbase"), data.obj = addBaseMerge3, geom = "geom", overwrite = FALSE)
)



#clip and clean data
addBaseMerge3BNGLDN <- addBaseMerge3BNG[londonOutline, ]
rm(list=setdiff(ls(), c("addBaseMerge3BNGLDN", "londonOutline", "conn")))
addBaseMerge3BNGLDNsub <- addBaseMerge3BNGLDN[1:100, ]
dbDrop(conn, name = c("gisapdata", "addbase_ldn"), type = "table")
pgInsert(conn, name = c("gisapdata", "addbase_ldn"), data.obj = addBaseMerge3BNGLDNsub, geom = "my_new_geom_column", new.id = "gid")

dbDisconnect(conn)