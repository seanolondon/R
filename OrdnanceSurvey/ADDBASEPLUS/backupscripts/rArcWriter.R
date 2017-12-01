rm(list=ls())
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
library(sp,lib = "C:/Program Files/R/R-3.4.1/library")
library(rgeos)
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
library(postGIStools, lib = "C:/Program Files/R/R-3.4.1/library")

arcgisbinding::arc.check_product()

setwd("D:/FME Scheduled_tasks/R_tasks")

today <- format(Sys.time(), "%Y%m")

###R spatial####

#write to GDB (Clipped & Unclipped)
conn <- dbConnect("PostgreSQL",dbname='gla_gis',host='gispostsqlaws.cbebbtl0e2o3.eu-west-1.rds.amazonaws.com',port='5432',user='gisapdata',password='gi$own')
dbListTables(conn)

dbGetQuery(conn, statement = "ALTER TABLE addbase_ldn ADD PRIMARY KEY (objectid)")
dbGetQuery(conn, statement = "ALTER TABLE addbase ADD PRIMARY KEY (objectid)")

#readFile <- paste0("D:/FME Scheduled_tasks/R_tasks/",today,"/address_base_london_",today,".csv")

#pgGetGeom(conn, name = c("gisapdata", "addbase_ldn"), geom = "geom", gid = "objectid") %>%
#pgGetGeomQ(conn, "SELECT * FROM addbase_ldn", geom_name = "geom", gid = "objectid")) %>%
#sf::st_read_db(conn, table = c("gisapdata", "addbase_ldn"), geom_column = "geom") 
f <- readOGR(dsn,"addbase_ldn")
arcgisbinding::arc.write(path = paste0("abp.gdb/addressBasePlusLondon_",today))

dbReadSpatial

pgGetGeom(conn, name = c("gisapdata", "addbase")) %>% 
  arcgisbinding::arc.write(path = paste0("abp.gdb/addressBasePlus_",today))

#CLEANUP TEMP FILES
finalCSV <- list.files(pattern = "csv")
finalZIP <- list.files(pattern = "zip")
finalBAT <- list.files(pattern = "bat")

for (i in 1:length(finalCSV)){
  if (file.exists(finalCSV[i])) file.remove(finalCSV[i])
} 

for (i in 1:length(finalZIP)){
  if (file.exists(finalZIP[i])) file.remove(finalZIP[i])
} 
for (i in 1:length(finalBAT)){
  if (file.exists(finalBAT[i])) file.remove(finalBAT[i])
} 

##schedule in jenkins ### 

#logfile start
#logfile start
sink(file = "D:\\FME Scheduled_tasks\\R_tasks\\abaseplus_automation_v0.9_log.txt", split = TRUE, append = FALSE)

Sys.time()
if(stringr::str_detect(list.files(path = paste0("D:/FME Scheduled_tasks/R_tasks/",today), pattern = "abp.gdb"), "abp.gdb")){
  print("SUCCESSFUL") } else {
    print("FAILED")
  }

sink(file = NULL)