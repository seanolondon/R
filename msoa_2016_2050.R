#read msoa excel table 
#sum all ages per year by MSOA
#aggregate 2016-2050, so total 2016-2015 per MSOA  

library(readxl)
library(tidyr)
library(dplyr)
library(WriteXLS)
library(rgdal)

#read in table
setwd("M:/Downloads")
persons1 <- read_excel("M:/Downloads/msoa_interim_2015_base.xlsx", sheet = "Persons")

#wide table to long 
longPerson1 <- gather(persons1, year, count, -GSS.Code.MSOA, -District, -Age)

#select from 2016-2015
longPerson16 <- subset(longPerson1, year == 2016)
longPerson50 <- subset(longPerson1, year == 2050) 

#collapse/summarise the age column to get all ages and sum 2016 & 2015 (group by MSOA code)
longPerson16collapse <- summarise(group_by(longPerson16, GSS.Code.MSOA), "Y2016" = sum(count))
longPerson50collapse <- summarise(group_by(longPerson50, GSS.Code.MSOA), "Y2050" = sum(count))
person1650 <- merge(longPerson16collapse,longPerson50collapse)

#create change column, as the difference from 2016 to 2015
person1650$change <- person1650$Y2050 - person1650$Y2016

#read base msoa shapefile from W drive
msoaSpatial <- readOGR("W:/GISDataMapInfo/BaseMapping/Boundaries/StatisticalBoundaries/Census_2011/SuperOutputAreas/London/Middle/ESRI/MSOA_2011_London.shp")

#merge the dataframe with the shapefile
spatial1650 <- merge(msoaSpatial, person1650, by.x = "MSOA11CD", by.y = "GSS.Code.MSOA")

#output/write the shapefile
writeOGR(obj=spatial1650, dsn=".", layer="msoaPersonsInterim1650", driver="ESRI Shapefile")
