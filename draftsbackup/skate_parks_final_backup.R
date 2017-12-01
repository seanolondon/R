#load tidyr
library(tidyr)
library(dplyr)

#read in table skate_park_data.csv
skate1 <- read.csv("skate_park_data.csv", na.strings= "  ")

#remove the X column
skate1 <- select(skate1, -X)

#remove skate parks with nothing in the tags column
skate1_blanks1 <- subset(skate1, is.na(skate1$tags))

#table as a vector, use jsut the tags column to get column headers  
col_names1 <- as.vector(skate1$tags)

#split the tags into indivudual works or hyphednated words 
col_names2 <- as.vector(strsplit(col_names1, split = " "))

#result is tag2 as a list, need to convert this to a vector to run the unique 
col_names3 <- unlist(col_names2)

#unique to get only single column names
col_names4 <- sort(unique(col_names3))

#trim blank column
col_names5 <- subset(col_names4, nchar(col_names4) > 1)

#create a blank table for parks without any tags, in the correct dimensions, append later
skate1_blanks2 <- select(skate1_blanks1, -tags)
skate1_blanks2[col_names5] <- NA

#separate function
skate2 <- separate_rows(skate1, tags, sep = " ", convert = TRUE)

#subset skate2 to have only rows with values in tags
skate3 <- subset(skate2, tags != "")

#reset row identifiers
rownames(skate3) <- seq(length=nrow(skate3))

#remove duplicate pairs - name and tag is the same
skate3 <- skate3[!duplicated(skate3[c("name","tags")]), ]

## UN-comment code below to keep long but append missing parks
# skate_long <- rbind(skate3, skate1_blanks1)
# write.csv
##table is now long, according to tidy data this should be TWO tables
##the below script creates a binary table which is not suggested 

#creates a column of TRUE vlaues for parks having tags
skate3$has <- 1

#pivot the table to make wide, using the key of tags - new columns, which match to has - TRUE/FALSE if there is anything 
skate4 <- spread(skate3, key = tags, value = has)

#append the missing 'blank' values back to the data frame 
skate5 <- rbind(skate4, skate1_blanks2)

#write csv, change to correct directory
write.csv(skate5, "skate_park_wide.csv")

head(skate5)
dim(skate5)