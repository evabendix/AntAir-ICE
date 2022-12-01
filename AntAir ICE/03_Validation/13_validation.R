# Seasonal validation and ERA5 comparison

library(raster)
library(stringr)
library(dplyr)
library(lubridate)
library(splitstackshape)
library(ggplot2)
library(ggpubr)
library(rgdal)
library(gdalUtils)
library(rgdal)
library(car)
library(caret)
library(maps)

rm(list=ls())
setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean")
path= "~/Documents/PhD/R/AntAIR2/Data" 


###################### AWS data ##########################
# Make dataframe from all AWS stations 
All_AWS = list.files(paste0(path,"/AWS_data/Stations_Daily_mean",sep=""))
txt_files_df <- lapply(All_AWS, function(x) {read.table(file = x, header = T, sep =",")})
# Combine them
combined_AWS_mean <- do.call("rbind", lapply(txt_files_df, as.data.frame)) 

combined_AWS_mean <-  combined_AWS_mean  %>% filter(combined_AWS_mean$T_air_daily > -100)

# Change column names 
colnames(combined_AWS_mean) = c("AWS_data.Name", "Date", "T_air_daily", "N_measurments")


# Coordinates for station 
AWS_data = read.table(file = paste0(path,"/AWS_data/Stations_Antarctica_all.txt",sep=""), 
                      header = T, sep =",",fill=TRUE)
Coord_AWS = data.frame(AWS_data$Name, AWS_data$Long,AWS_data$Lat)


###################### AntAir data ##########################

