## warning using remove all variables! 
rm(list=ls(all=TRUE))

## httr for unlocking, XML for reading webpages, dplyr for mutate, xlsx for read/write, lubridate for dates
library(httr)
library(XML)
library(dplyr)
library(xlsx)
library(lubridate)

## set working directory: R:\K\Projects\Communities\Health\Healthy Schools London\Data
setwd("R:/K/Projects/Communities/Health/Healthy Schools London/Data")

## test to see if a folder exists for today's date CAN BE DELETED
today <- paste(Sys.Date())
today2 <- gsub("-","",today)
dir.exists(today2)

## test if folder exists, if not create a directory of today without hypens, setwd to new folder
if(!dir.exists(today2))
  {dir.create(today2)}
setwd(today2)

## May need to login on web browser to get the cookies, get cookie matching: SESS8a483807592c708d17a52f0740db2bca
CookieKeyChange <- "fqrMhhhWexsyVucRXjiRDBQFQfZTwlqKEMm3WwlvEDU	"

## May need to login on web browser to get the cookies, get cookie matching: SESS8a483807592c708d17a52f0740db2bca
## inspect page>application>cookies> set cookies from 3rd option to _gat
## login to http://www.healthyschools.london.gov.uk/user 
h <- handle("http://www.healthyschools.london.gov.uk/")
url1 <- "http://www.healthyschools.london.gov.uk/user"
auth1 <- GET(url1, set_cookies(`SESS8a483807592c708d17a52f0740db2bca` = CookieKeyChange, `__cfduid` = "df8f4a27abe9ac23867fb0200850d2d941489484870", `__utma` = "166127271.1614365760.1488800194.1488802750.1488809602.3", `__utmz` = "166127271.1488800194.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", `__ga` = "GA1.3.1678467372.1489484871", `__gat` = "1"), authenticate("Michael Jeffrey", "Hsl.321"))
auth2 <- GET(url = "http://www.healthyschools.london.gov.uk/awards/summary", set_cookies(`SESS8a483807592c708d17a52f0740db2bca` = CookieKeyChange, `__cfduid` = "df8f4a27abe9ac23867fb0200850d2d941489484870", `__utma` = "166127271.1614365760.1488800194.1488802750.1488809602.3", `__utmz` = "166127271.1488800194.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", `__ga` = "GA1.3.1678467372.1489484871", `__gat` = "1"), path="/awards")
auth3 <- GET(url = "http://www.healthyschools.london.gov.uk/awards/summary", set_cookies(`SESS8a483807592c708d17a52f0740db2bca` = CookieKeyChange, `__cfduid` = "df8f4a27abe9ac23867fb0200850d2d941489484870", `__utma` = "166127271.1614365760.1488800194.1488802750.1488809602.3", `__utmz` = "166127271.1488800194.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", `__ga` = "GA1.3.1678467372.1489484871", `__gat` = "1"), path="/awards/summary")

## Test to see if reading in the HTML page via XML works 
##content1 <- content(auth1,as="text")
##parsedHTML <- htmlParse(content1,asText=TRUE)
##xpathSApply(parsedHTML, "//title", xmlValue)

## Read in Table text of award applications and returns all as a single line
content2 <- content(auth2,as="text")
parsedHTML <- htmlParse(content2,asText=TRUE)
rawtable <- xpathSApply(parsedHTML, "//tr", xmlValue)

## Read in webpage as text, locate the 'table' in the page and convert it to table format/dataframe
content3 <- content(auth3,as="text")
AwardSumTable <- readHTMLTable(content3)
AwardSumTable2 <- as.data.frame(AwardSumTable)

#rename fields to match original---these may change occasionally--5 mistakes originally
AwardSumTable2$NULL.Borough <- sub("City & Hackney", "City and Hackney",AwardSumTable2$NULL.Borough)
AwardSumTable2$NULL.Borough <- sub("Hammersmith & Fulham","Hammersmith and Fulham",AwardSumTable2$NULL.Borough)
AwardSumTable2$NULL.Borough <- sub("Kensington & Chelsea","Kensington and Chelsea",AwardSumTable2$NULL.Borough)
AwardSumTable2$NULL.Borough <- sub("Kingston-upon-Thames","Kingston upon Thames",AwardSumTable2$NULL.Borough)
AwardSumTable2$NULL.Borough <- sub("Richmond-upon-Thames","Richmond upon Thames",AwardSumTable2$NULL.Borough)

## Format table rename columns, remove first line
colnames(AwardSumTable2) <- c("BOROUGH", "REGISTERED", "BRONZE", "SILVER", "GOLD")
AwardSumTable3 <- AwardSumTable2[2:33, ]

## Set alphabetical order on borough, save as an excel file without column index/row names 
AwardSumTable3 <- AwardSumTable3[order(AwardSumTable3$BOROUGH),]
write.xlsx(AwardSumTable3, file = "schools_summary.xlsx", row.names = FALSE)

## read in registrations
registrations <- read.csv("R:/K/Projects/Communities/Health/Healthy Schools London/Data/REGISTRATIONS.csv")

## append/cbind column from AwardSumTable3, header is THIS MONTH as in use Date/Sys.Date
thismonth <- toupper(month(Sys.Date(), label = TRUE, abbr = TRUE))
test <- merge(registrations, AwardSumTable3, by.x = "NAME", by.y = "BOROUGH")

##remove extra field names and rename to this month
test2 = test[,!(names(test) %in% c("BRONZE","SILVER","GOLD"))]
names(test2)[names(test2) == 'REGISTERED'] <- thismonth

##rewrite registrations file
write.csv(test2, file = ("R:/K/Projects/Communities/Health/Healthy Schools London/Data/REGISTRATIONS.csv"), row.names = FALSE)

## download CSV file from http://www.healthyschools.london.gov.uk/schools_report 
## get link from bottom left side of page, use cookies, write_disk, and progress() to see the result of download
setwd("R:/K/Projects/Communities/Health/Healthy Schools London/Data")
GET(url = "http://www.healthyschools.london.gov.uk/admin/reports/schools_report/schools_report_full.csv", set_cookies(`SESS8a483807592c708d17a52f0740db2bca` = CookieKeyChange, `__cfduid` = "df8f4a27abe9ac23867fb0200850d2d941489484870", `__utma` = "166127271.1614365760.1488800194.1488802750.1488809602.3", `__utmz` = "166127271.1488800194.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", `__ga` = "GA1.3.1678467372.1489484871", `__gat` = "1"), path="admin/reports/schools_report/schools_report_full.csv", write_disk("schoolsresport.csv"), progress())

## read the schools reports, store as a DF
## Combine school name and borough to find duplicates, return rows with duplicates, school name, and borough
schoolsreport <- read.csv("R:/K/Projects/Communities/Health/Healthy Schools London/Data/schoolsresport.csv")
schoolsreport2 <- mutate(schoolsreport, uniqschool = paste(School.name, Borough.name))
duplicaterow <- which(duplicated(schoolsreport2$uniqschool))
schoolsreport[duplicaterow, c(1,19)]

##remove temporary data 
setwd("~/")


