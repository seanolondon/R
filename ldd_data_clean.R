library(data.table,lib = "C:/Program Files/R/R-3.4.1/library")
library(dplyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(tidyr,lib = "C:/Program Files/R/R-3.4.1/library")
library(lubridate,lib = "C:/Program Files/R/R-3.4.1/library")
library(stringr,lib = "C:/Program Files/R/R-3.4.1/library")

rm(list=ls())

data <- read.csv(file = "R:/K/Projects/Development/Planning/London_Infrastructure_Plan_2050/data/recieved/BarbourABI/download/sftp/691615_13-Nov-17.txt")

head(data)
glimpse(data)
names(data)
nrow(data)

postcodeRegex <- "^([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9]?[A-Za-z])))) [0-9][A-Za-z]{2})$"

#return row nums valid postcodes
validRows <- grep(postcodeRegex, data$Pcode)

dataPC <- data[validRows, ]

dataMissingValidPC <- data[!(data$Ptno %in% dataPC$Ptno), ]

### Next steps? 

datesDF <- data[,c(1, 17,20,22,24)]

datesDF <- datesDF %>%
            filter(Start_date > 0 & Completion_date > 0) %>%
            mutate(start_lrg_err = (Completion_date - Start_date))

setwd("M:/LDD/2017")
list.files()
barbour <- read.csv("barbour.csv")
ldd <- read.csv("ldd_data.csv")

ldd2 <- ldd[names(ldd) %in% c("borough_ref", "descr", "post_code")]
ldd2 %>% mutate(lddid = paste0("ldd", seq_len(nrow(ldd2))))

barbour2 <- barbour[names(barbour) %in% c("planning_ref", "Scheme", "Pcode")]
barbour2 %>% mutate(barbourid = paste0("barb", seq_len(nrow(barbour2))))





