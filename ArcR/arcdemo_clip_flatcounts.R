#originally ran on IU-1
#clip by london villages
#create counts of flats
#group by village

#install.packages(c("rgdal", "data.table", "dplyr", "tidyr", "RCurl", "curl", "RPostgreSQL", "rpostgis", "raster"), lib = "C:/Program Files/R/R-3.4.1/library")

library(rgdal,lib = "C:/Program Files/R/R-3.4.1/library")
library(data.table,lib = "C:/Program Files/R/R-3.4.1/library")
library(dplyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(tidyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(sf,lib = "C:/Program Files/R/R-3.4.1/library")

##########

library(arcgisbinding, lib = "C:/Program Files/R/R-3.4.1/library")
arc.check_product()

##########

rm(list=ls())

setwd("C:/Data/temp")

#read in data
dataLocation <- "C:/Data/temp"
addbaseLocation <- "C:/Data/temp/addresses.gdb"

wardsLDN <- readOGR(dsn = dataLocation, layer = "newham_wards")


system.time({
#time of process below:  305.00   69.39  375.61
addbaseOGR <- readOGR(dsn = addbaseLocation, layer = "addbase_plus_selection_april_2017")

addbaseOGR <- spTransform(addbaseOGR, CRS(proj4string(wardsLDN)))

##clip & sum flats as features with same XY ---- not really needed because of join later
addbaseClipped <- addbaseOGR[wardsLDN, ]
                  
flats <- addbaseClipped@data %>%
                    mutate(XY = paste0(x_coordinate, y_coordinate)) %>%
                    add_count(XY) %>%
                    distinct(XY, .keep_all = TRUE) %>%
                    rename(FLAT = n) %>%
                    select(c(FLAT, ward_code)) %>%
                    filter(FLAT > 1) %>%
                    group_by(ward_code) %>%
                    mutate(total_flats = sum(FLAT)) %>%
                    distinct(ward_code, .keep_all = TRUE) %>%
                    select(c(ward_code, total_flats))


wardsLDN@data <- inner_join(wardsLDN@data, flats, by = c("GSS_CODE" = "ward_code"))

})

#time of process below: 140.58    2.06  142.81 
system.time({
addbaseST <- st_read(dsn = addbaseLocation, layer = "addbase_plus_selection_april_2017")

wardsLDN <- readOGR(dsn = dataLocation, layer = "newham_wards")

flatsST <- addbaseST %>%
            mutate(XY = paste0(x_coordinate, y_coordinate)) %>%
            add_count(XY) %>%
            distinct(XY, .keep_all = TRUE) %>%
            rename(FLAT = n) %>%
            select(c(FLAT, ward_code)) %>%
            filter(FLAT > 1) %>%
            group_by(ward_code) %>%
            mutate(total_flats = sum(FLAT)) %>%
            distinct(ward_code, .keep_all = TRUE) %>%
            select(c(ward_code, total_flats))

wardsLDN@data <- inner_join(wardsLDN@data, flatsST, by = c("GSS_CODE" = "ward_code"))

})

arc.write(wardsLDN, path = "addresses.gdb/newhamflats_ward")

#note: use 'over' for area on area, or 'crop' for a proper/true clip of area on area

#for time series of addabse plus: W:\GISDataMapInfo\BaseMapping\Addressing\OSAddressBasePlus\OSAddressBasePlus.gdb




                  
                  