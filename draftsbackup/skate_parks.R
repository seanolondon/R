#load tidyr
library(tidyr)
library(dplyr)
library(readr)


#read in table
skate1 <- read.csv("skate_park_data.csv" )

#subset park name and tags
skate1 <- skate1[,c(1,2,6)]

#table as a vector, use jsut the tags column to get column headers  
col_names1 <- as.vector(skate1$tags)

#split the tags into indivudual works or hyphednated words 
col_names2 <- as.vector(strsplit(tags1, split = " "))

#result is tag2 as a list, need to convert this to a vector to run the unique 
col_names3 <- unlist(tags2)

#unique to get only single column names
col_names4 <- sort(unique(tags3))

#separate function
skate2 <- separate(skate1, tags, into = col_names4, sep = " ")

skate3 <- gather(skate2, key = park, value = feature, name:Wood, na.rm = TRUE, factor_key = TRUE)

head(skate3, n=50)
dim(skate3)