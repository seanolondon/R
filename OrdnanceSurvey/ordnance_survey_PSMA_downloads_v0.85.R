#Automation of Ordnance Survey data from the Public Sector Mapping Agreement (PSMA)
#v0.8 runs fine but is for the out of date master map, to update to 0.9 must be able to download newest only.  

#Download update of OS MasterMap Topography Layer - 5km

#clear all variables
rm(list=ls())
#for web nav
library(httr)
#web forms
library(rvest)
library(XML)
#for piping
library(magrittr)
library(stringr)
library(lubridate)
#to read gml
library(multiplex)
library(rgdal)

#setwd
setwd(normalizePath("Q:\\Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\OS MasterMap Topography Layer\\downloaded"))

#password to login as paul, KEEP ON PERSONAL M: DRIVE, NOT PUBLIC 
source("M:/ProgrammingScripts/R/pwords/psma.R")
#osLoginUrl <- GET("https://www.ordnancesurvey.co.uk/sso/login.shtml", authenticate(username, password))

#using rvest to locate form on page
url<-"https://www.ordnancesurvey.co.uk/orderdownload/orders"   ## page to spider
pgsession <-html_session(url)               ## create session
pgform <-html_form(pgsession)[[1]]       ## pull form from session

#fill and submit form
filled_form <- set_values(pgform, userid = username, password = password)
session1 <- submit_form(pgsession,filled_form)

#scrape the download list page
orderNumber <- html_nodes(session1, ".row0 td") %>% html_text()
updateDate <- html_node(session1, ".row0 td.sortColumn") %>% html_text()

#order type and date match  SET THIS AFTER FINISHING : dmy(updateDate)
#if (str_detect(orderNumber[3], "MasterMap") && dmy("5 July 2017") == Sys.Date()) {


#follow first download link to first page
linkText1 <- session1 %>% 
  follow_link(i = 20) %>% ## this returns the first order, 20 = 3rd order, 19 = 2nd order, 18 = 1st order
  html_node("#orderLinks") %>% # which line to pull text from, all the file names
  html_text() # turn into readable text

#html raw text to vector of files to download
linkText2 <- str_split(linkText1, '[\r\n\t]')
linkText3 <- unlist(linkText2)
linkText4 <- linkText3[linkText3 != ""]
linkText4 <- gsub(" ", "_", linkText4)
linkText4 <- gsub("-", "_", linkText4)

#download all the <li> items
#use linkText4 with an lapply function 
#follow first download link to first page
download1 <- session1 %>% 
  follow_link(i = 20) %>% ## 20 = 3rd order, 19 = 2nd order, 18 = 1st order
  html_nodes("a") %>%  #link nodes
  html_attr("href") #attributes with a hyperlink

download2 <- download1[nchar(download1) > 250] #correct type of hypertext, short ones are ignored
download3 <- download2[!is.na(download2)]

# test to see if a folder exists for today's date CAN BE DELETED
today <- Sys.Date()
today2 <- gsub("-","",today)
dir.exists(today2)

# test if folder exists, if not create a directory of today without hyphens, setwd to new folder
if(!dir.exists(today2))
{dir.create(today2)}
setwd(today2)

#delete after unzip works
#linkText4 <- linkText4[1:2]

#download all zip files from the links
#for (i in 1:length(linkText4)) {
#  download.file(download3[i], destfile = linkText4[i],method = "curl")
#}

#put together codes to initialize 7zip in the bat files, define the 'path' to 7zip 
#7zip will only work on machines with 7zip installed
# CODE MAY NOT DO ANYTHING, IS HERE IN CASE BLANK FILES ARE COMING FROM OS
# UNZIPPING MAY NOT BE NEEDED IF FILES ARE CORRECT, BUT CODE REMAINS IN CASE THERE ARE ISSUES
begginingCmd <- c("set PATH=%PATH%;C:\\Program Files\\7-Zip\\", "echo %PATH%", "7z", "cd /d q:", paste0("cd Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\OS MasterMap Topography Layer\\downloaded\\", today2))
files <- list.files(path = ".", pattern = "^[^.]+$")
zipList <- c()
for (i in 1:length(files)) {
  zipList[i] <- paste("7z e", files[i])
}

#put together the list of files and the beginning cmd commands, write to a .bat files
zipcmd <- as.data.frame(append(begginingCmd, zipList))
write.table(zipcmd, file = "list.bat", quote = FALSE, col.names = FALSE, row.names = FALSE)

#command line unzip using 7zip from the list.bat file 
shell("list") ###athe list.bat file in downloaded folder
#shell(paste0("cd /d q: && cd Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\OS MasterMap Topography Layer\\downloaded\\", today2," && list")) ###adjust to today2

#select files which only have a period or are CSV, rename them to gz or gml 
#NOTE: This may not have any affect but in the beginning of July 2017 files were coming with out definition
if (length(list.files(path = ".", pattern = "^[^.]+$")) > 0) {
  listedUnpack <- list.files(path = ".", pattern = "^[^.]+$")
  file.rename(listedUnpack, paste0(listedUnpack, ".gml"))
} else if (length(list.files(path = ".", pattern = "csv")) > 0){
  listedUnpackCSV <- list.files(path = ".", pattern = "csv")
  file.rename(listedUnpackCSV, gsub(".csv", ".gz", listedUnpackCSV))
}

#define the parameters for the FME process, plus the location of FME, the FME process, plus ways to change drives in commandline
writerLocation <- paste0("\"","C:/temp/","osmm_",today2,"\"")
cdC <- c("cd /d c:")
cdQ <- c("cd /d q:")
fmeLocation <- paste0("\"","C:\\Program Files\\FME\\2017\\fme.exe","\"")
fmeFile <- paste0("\"","Q:\\Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\OS MasterMap Topography Layer\\MasterMap_2016_08_FULL\\fme\\convert_mm_to_gdb_working_bat.fmw","\"")

#loop writing then overwriting a bat file, with FME parameters, formatted in the cmd way. the loop also runs the fme process at each iteration
#for (i in 1:length(list.files(path = ".", pattern = ".gz"))) {
for (i in 29:33) {
  #may be having errors in function running over midnight
  print(Sys.time())
  #define location of files to run through fme
  gmlLocation <- paste0("\"","Q:\\Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\OS MasterMap Topography Layer\\downloaded\\", today2,"\\",list.files(path = ".", pattern = ".gz"),"\"")
  #contents of the bat file, including paramaters for the FME process
  makeBat <- paste(fmeLocation, fmeFile, "--SourceDataset_GML", gmlLocation[i], "--DestDataset_GDB", writerLocation)
  #write the bat file
  write.table(makeBat, file = paste0("fme.bat"), quote = FALSE, col.names = FALSE, row.names = FALSE)
  shell("fme")
  #shell(paste0("cd /d q: && cd Teams\\GIS&I\\GIS\\Processing\\OrdnanceSurvey\\OS MasterMap Topography Layer\\downloaded\\", today2," && fme"))
}

#} else{
#  print("MasterMap has not been updated")
#}


#schedule in Jenkins 


