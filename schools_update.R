## UPDATE SCHOOLS DATA FOR THE SCHOOLS ATLAS

## The process reads the most recent edubase data, and merges it with the live schools data
## There is also an update of the healthy schools column 
## after running the process the output should be copied accross to the W: drive 

## workforce Data from: https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/533536/SFR21-2016_UD_CSV.zip
##School workforce in England: November 2015 > Underlying data including metadata file: SFR21/2016 (CSV format )

## The input files for the script will need to be located if doing an update, so fgdb and workforce

## Written by Sean O'Donnell
## April 10, 2017

library(dplyr)
library(rgdal)

# The input file geodatabase of edubase data
fgdb = "W:/GISDataMapInfo/Themes/Education/EduBase/ESRI/Edubase_20170401.gdb"

## Live location to append the new edubase data -- UPDATE AFTER TESTING
##SchoolsLive = "D:/data/gisdata/apps/LondonSchoolsAtlas/LSA_2016_Jan17_web.gdb"

# List all feature classes in a file geodatabase
subset(ogrDrivers(), grepl("GDB", name))
fc_list = ogrListLayers(fgdb)
print(fc_list)

# Read the feature class
fc = readOGR(dsn=fgdb,layer="Edubase_Schools_20170401")

## Check if column name exists in Edubase, if so rename to schools data column name
colnames(fc@data)[which(names(fc) == "EstablishmentName")] <- "SCHOOL_NAME"
colnames(fc@data)[which(names(fc) == "TypeOfEstablishment__name_")] <- "TYPE"
colnames(fc@data)[which(names(fc) == "PhaseOfEducation__name_")] <- "PHASE"
colnames(fc@data)[which(names(fc) == "Street")] <- "ADDRESS"
colnames(fc@data)[which(names(fc) == "Town")] <- "TOWN"
colnames(fc@data)[which(names(fc) == "EstablishmentStatus__name_")] <- "STATUS"
colnames(fc@data)[which(names(fc) == "Gender__name_")] <- "GENDER"
colnames(fc@data)[which(names(fc) == "WardNM")] <- "WARD_NAME"
colnames(fc@data)[which(names(fc) == "LSOA11NM")] <- "LSOA_NAME"
colnames(fc@data)[which(names(fc) == "LAD11NM")] <- "LA_NAME"
colnames(fc@data)[which(names(fc) == "SchoolWebsite")] <- "WEBLINK"
colnames(fc@data)[which(names(fc) == "Postcode")] <- "POSTCODE"
colnames(fc@data)[which(names(fc) == "NumberOfBoys")] <- "NoofBoys"
colnames(fc@data)[which(names(fc) == "NumberOfGirls")] <- "NoofGirls"
##colnames(fc@data)[which(names(fc) == "NumberOfPupilspils")] <- "NumberOfPupils"
colnames(fc@data)[which(names(fc) == "PercentageFSM")] <- "PerFSM"
colnames(fc@data)[which(names(fc) == "TelephoneNum")] <- "Tele"
colnames(fc@data)[which(names(fc) == "OfstedSpecialMeasures__name_")] <- "ofsted"

## Calculated fields, e.g. "StatutoryLowAge" & "-" & "StatutoryHighAge" = "AGE" # calculate
fc$AGE <- paste(fc$StatutoryLowAge, fc$StatutoryHighAge, sep = "-")
fc$BoyGirl_R <- round((as.numeric(fc$NoofBoys) /  as.numeric(fc$NoofGirls)), digits = 4)
fc$Tele <- paste(substr(fc$Tele, 1,4), substr(fc$Tele, 5,11), sep = " ")
fc$ofsted <- gsub("Not in special measures", 1, fc$ofsted)  
fc$ofsted <- gsub("Not applicable", 2, fc$ofsted)
fc$ofsted <- gsub("In special measures", 3, fc$ofsted)

##Create a spatial data frame of useful variables from Edubase Data
df <- subset(fc, select = c(URN,SCHOOL_NAME,TYPE, PHASE, ADDRESS, TOWN, STATUS, WARD_NAME, GENDER, LSOA_NAME, LA_NAME, WEBLINK, POSTCODE, NoofBoys, NoofGirls, NumberOfPupils, PerFSM, Tele, AGE, BoyGirl_R, ofsted, HeadLastName))

##read in school data from file geodatabase ##### CHANGE TO R DRIVE SCHOOL DATA!!!
schoolData <- "R:/K/Projects/Intelligence/D&PA/SRP/Data/2016_update/all_schoolsJan17.gdb"
sd = readOGR(dsn=schoolData,layer="school_data_ew_2017")

##subset the data School Data, remove columns which match Edubase data as that is the update
sdSubset <- sd[,c(1,14,15,25:44)]

##Merge the Edubase data with the School Data, where the 'x' data is the edubase data. 
##The Edubase data should be longer than the Schools Data
dfsd <- sp::merge(sdSubset, df, by.x = "URN", by.y = "URN")

##read in workforce data (to get teacher pupil ratio)
workforce <- read.csv("R:/K/Projects/Intelligence/D&PA/SRP/Data/workforce/SFR21-2016_Schools.csv")

##subset workforce data
subworkforce <- workforce[,c(5,32)]

##merge the workforce data
dfsdwf <- merge(dfsd, subworkforce, by.x = "URN", by.y = "URN")

##Rename fields and remove duplicate old data PupilTeacher ratio
##dfsdwf <- subset(dfsdwf, select = -PupilTeach)
colnames(dfsdwf@data)[which(names(dfsdwf) == "Pupil......Teacher.Ratio")] <- "PupilTeach_R"

##reorder fields (no OBJECTID)
##schools <- subset(dfsdwf, select = c(2,1,24,25,26,27,28,35,29,31,30,33,34,41,3,40,36,37,42,39,47,43,4,32,38,44)
schools <- subset(dfsdwf, select = c(URN,SCHOOL_NAME,TYPE,PHASE,ADDRESS,TOWN,POSTCODE,STATUS,GENDER,WARD_NAME,LA_NAME,WEBLINK,AGE,Primary,Tele,NoofBoys,NoofGirls,BoyGirl_R,PerFSM,PupilTeach_R,ofsted,PTREADWRITTAMAT4B_2013,PTREADWRITTAMAT4B_LON_2013,PTREADWRITTAMAT4B_2014,PTREADWRITTAMAT4B_LON_2014,PTREADWRITTAMAT4B_2015,PTREADWRITTAMAT4B_LON_2015,PTAC5EM_PTQ_EE_2012,PTAC5EM_PTQ_EE_LON_2012,PTAC5EM_PTQ_EE_2013,PTAC5EM_PTQ_EE_LON_2013,PTAC5EM_PTQ_EE_2014,PTAC5EM_PTQ_EE_LON_2014,PTAC5EM_PTQ_EE_2015,PTAC5EM_PTQ_EE_LON_2015,goldclub_2014,goldclub_2015,goldclub_2016,map_icon_level,healthyschools_2015,Ambassdors_2016,LSOA_NAME,NumberOfPupils,HeadLastName))                  
schools$WEBLINK <- as.character(schools$WEBLINK)
schools$SCHOOL_NAME <- as.character(schools$SCHOOL_NAME)
schools$TYPE <- as.character(schools$TYPE)
schools$PHASE <- as.character(schools$PHASE)
schools$ADDRESS <- as.character(schools$ADDRESS)
schools$TOWN <- as.character(schools$TOWN)
schools$POSTCODE <- as.character(schools$POSTCODE)
schools$STATUS <- as.character(schools$STATUS)
schools$GENDER <- as.character(schools$GENDER)
schools$WARD_NAME <- as.character(schools$WARD_NAME)

## update healthy schyools column. 
##The report comes from the award_summary.R process which requires a login & a cookie code
healthy <- read.csv("R:/K/Projects/Communities/Health/Healthy Schools London/Data/schoolsresport.csv")

##rename boroughs with characters & or - to spaces
healthy[,19] <- gsub(' & ', ' and ', healthy[,19])
healthy[,19] <- gsub('-', ' ', healthy[,19])

## create a new column 'working' of school name + area name
healthy$working <- paste(healthy[,1], healthy[,19])
schools@data$working <- paste(schools@data$SCHOOL_NAME, schools@data$LA_NAME)

##create variables to match to
healthyurn <- trimws(as.vector(healthy[,21]))
healthypost <- gsub(' ','',as.vector(casefold(healthy[,17], upper = TRUE)))
healthyworking <- as.vector(healthy[,35])

## schools atlas postcodes for matching
postcodes <- gsub(' ','',schools@data$POSTCODE)

### URN > PostCode > School Name & Area name
## postcodes which have a value in the schools column --NEED HELP ON HOW TO MATCH! -- Match 1898
schools@data$healthyschools_2017 <- ifelse((schools@data$URN %in% healthyurn) | (postcodes %in% healthypost) | (schools@data$working %in% healthyworking), 1, 0)
healthy$found <- ifelse((healthyurn %in% schools@data$URN) | (healthypost %in% postcodes) | (healthyworking %in% schools@data$working), 1, 0)

## Activate to check matching
##sum(schools@data$healthyschools_2017)
##sum(healthy$found)
##names(schools)

##reorder and remove fields for final output to remove working fields
##schools <- subset(schools, select = c(-working, -HeadLastName, -healthyschools_2015))
schools <- schools[,c(1:38,46,41,39,42,43)]

#### may need to be re-formatted or re-looked at in the future
schools$URN <- as.character(schools$URN)

#######################WRITING#############################

## naming done by date, so if needed to overwrite on the SAME day delete the same day output and repeat the script

##Ensure the projection is British National Grid using Proj4 
##If warnings just ignore; this just makes certain the output is always BNG 
proj4string(schools) <- "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs"
plot(schools)

##write the output, modify dsn for destination and obj for shapefile name. 
##Overwriting layers could be useful but there is a warning about instability
##A warning will be generated - column names are shortened, but is fine since there is also a GDB writer
naming <- paste("schools", Sys.Date(), sep = "_")
location <- "R:/K/Projects/Intelligence/D&PA/SRP/Data/2016_update/performance_stats/schools_update_output"
writeOGR(obj = schools, dsn=location, layer=naming, driver="ESRI Shapefile", overwrite_layer=FALSE)

##write a csv file if the column names from the shape file corrupts
write.csv(schools, file = (gsub("-","_",gsub(" ","",paste(location,"/",naming,".csv")))))

##write to file geodatabase MUST BE DONE IN 32-Bit R and on GLA-IU-1. 
##To open 32 bit in RStudio hold 'Ctrl' when opening studio then select 32 bit. 
##For a new installation check here: https://github.com/R-ArcGIS/r-bridge-install#offline-installation 
library(arcgisbinding)
arc.check_product()

##the patch can be modified, see the location object and also keep the space remover (gsub)
arc.write(path = (gsub("-","_",gsub(" ","",paste(location,"/","schools.gdb/",naming)))), data = schools)
