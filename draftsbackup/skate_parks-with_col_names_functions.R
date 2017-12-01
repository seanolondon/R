#load tidyr
library(tidyr)
library(dplyr)
library(readr)


#read in table skate_park_data.csv
skate1 <- read.csv("skate_park_data.csv", na.strings= "  ")

#remove the X column
skate1 <- skate1[,2:6]

skate1_blanks <- subset(skate1, is.na(skate1$tags))

#table as a vector, use jsut the tags column to get column headers  
#col_names1 <- as.vector(skate1$tags)

#split the tags into indivudual works or hyphednated words 
#col_names2 <- as.vector(strsplit(col_names1, split = " "))

#result is tag2 as a list, need to convert this to a vector to run the unique 
#col_names3 <- unlist(col_names2)

#unique to get only single column names
#col_names4 <- sort(unique(col_names3))

#trim blank column
#col_names5 <- col_names4[2:13]

#separate function
skate2 <- separate_rows(skate1, tags, sep = " ", convert = TRUE)

#subset skate2 to have only rows with values in tags
skate3 <- subset(skate2, tags != "  ")

#reset row identifiers
rownames(skate3) <- seq(length=nrow(skate3))

#remove duplicate pairs - name and tag is the same
skate3 <- skate3[!duplicated(skate3[c("name","tags")]), ]

head(skate3, n=70)
dim(skate3)

##table is now long, according to tidy data this should be two tables
## the below script creates a binary table which is not suggested 

#spread to make the table wide. 
skate3$has <- 1
skate4 <- spread(skate3, key = tags, value = has)

head(skate4)
dim(skate4)