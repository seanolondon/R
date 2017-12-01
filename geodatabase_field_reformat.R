#change field type in a geodatabase

rm(list=ls())

library(magrittr,lib = "C:/Program Files/R/R-3.4.1/library")
library(multiplex,lib = "C:/Program Files/R/R-3.4.1/library")
library(rgdal,lib = "C:/Program Files/R/R-3.4.1/library")
library(data.table,lib = "C:/Program Files/R/R-3.4.1/library")
library(dplyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(tidyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(sf,lib = "C:/Program Files/R/R-3.4.1/library")
library(stringr,lib = "C:/Program Files/R/R-3.4.1/library")
library(arcgisbinding, lib = "C:/Program Files/R/R-3.4.1/library")
arc.check_product()

geodatabase <- "W:/GISDataMapInfo/BaseMapping/Addressing/OSAddressBasePlus/OSAddressBasePlus.gdb"

featureClass <- readOGR(dsn = geodatabase, layer = "addressBasePlusLondon_201710_2")

featureClass2 <- featureClass[1:100, ]

test <- as(featureClass2, "Spatial")

rownames(featureClass2) <- featureClass2[,1]

featureClass2$uprn <- as.factor(featureClass2$uprn)

arc.write(test, path = "D:/FME Scheduled_tasks/R_tasks/abp.gdb/addressBasePlusLondon_201710_2")

