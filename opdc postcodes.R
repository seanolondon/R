library(rgeos)
library(sp)
library(rgdal)
pacman::p_load(dplyr, data.table, tidyr)

rm(list=ls())

area_names <- data.frame(OBJECTID = as.factor(c(6,7,5,3,9,11,8,10,12)),
                         Sub_Area = c("Northern Park Royal",
                                      "Southern Park Royal",
                                      "Victoria RD & Old Oak Lane",
                                      "Main Development Area",
                                      "Harlesden Fringe",
                                      "Rhapsody Court",
                                      "Park Royal Fringe",
                                      "North Kensington Fringe",
                                      "East Acton Fringe"))

####DO SOME GIS####

#Join the large sites point data to ward and MSOA polygons

setwd("N:/jasper/Shapefiles")
opdc <- readOGR(dsn = ".", layer = "opdc_sub_areas")

opdc@data <- left_join(opdc@data, area_names, by="OBJECTID")
head(opdc@data)

postcodes <- readOGR(dsn = "W:/GISDataMapInfo/BaseMapping/Addressing/OSCodePoint/2017_Jan/London.gdb",
                     layer = "Postcodes_London2017")

proj4string(opdc) <- proj4string(postcodes)

data_join <- cbind(as.data.frame(postcodes), over(postcodes, opdc)) %>%
        filter(!is.na(Sub_Area)) %>%
        select(POSTCODE, DISTRICT_NAME, Sub_Area)

data_join <- left_join(data_join, area_names, by="OBJECTID")
