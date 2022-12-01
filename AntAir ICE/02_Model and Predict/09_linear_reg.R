#Estimate LST and IST model 

rm(list=ls())

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
library(data.table)
library(ModelMetrics)

setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean")
path= "~/Documents/PhD/R/AntAIR2/Data" 


# Make dataframe from all AWS stations 
All_AWS = list.files(paste0(path,"/AWS_data/Stations_Daily_mean",sep=""))
txt_files_df <- lapply(All_AWS, function(x) {read.table(file = x, header = T, sep =",")})

# Combine them
combined_AWS_mean <- do.call("rbind", lapply(txt_files_df, as.data.frame)) 
colnames(combined_AWS_mean) = c("AWS_data.Name", "Date", "T_air_daily", "N_measurments")



AWS_data = read.table(file = "/Users/Eva/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Antarctica_all.txt", 
                      header = T, sep =",",fill=TRUE)
Coord_AWS = data.frame(AWS_data$Long,AWS_data$Lat )
AWS_coord_Sp = SpatialPointsDataFrame(coords = Coord_AWS, data = Coord_AWS,
                                      proj4string = crs("+init=epsg:4326"))
AWS_coord = spTransform(AWS_coord_Sp, CRSobj = CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))

Coord_AWS2 = data.frame(AWS_data$Name,AWS_data$Long,AWS_data$Lat )
colnames(Coord_AWS2) = c('AWS_data.Name','Long', 'Lat')



# Add LST temperature files 
setwd("~/Documents/PhD/R/AntAIR2/Data/MODIS_temp")


LST_data = list.files("~/Documents/PhD/R/AntAIR2/Data/MODIS_temp", pattern= "Surface_temperature*")
LST_files_df <- lapply(LST_data, function(x) {read.table(file = x, header = T, sep =",", fill = TRUE)})
# Combine them
combined_LST <- do.call("rbind", lapply(LST_files_df , as.data.frame)) 

# Converte LST date from formate d-m-y to y-m-d
combined_LST$Date = as.Date.character(combined_LST$Date, format="%d-%m-%Y")
combined_LST$Date = as.character(combined_LST$Date)


QA_file = read.table("/Users/Eva/Documents/PhD/R/AntAIR2/Data/MODIS_temp/Surface_QA_total.txt", header = T, sep =",", fill = TRUE)
QA_file$Date = as.Date.character(QA_file$Date, format="%d-%m-%Y")
QA_file$Date = as.character(QA_file$Date)



combined_LST <- merge(combined_LST, QA_file, by = c('AWS_data.Name','Date'))


# LST selection ---------------------------------------------------------------


# Join LST and AWS dataframes from date 
joineddataset <- merge(combined_AWS_mean, combined_LST, by = c('AWS_data.Name','Date'))

# Get valid LST 
v_LST = c("LST_MOD_day", "LST_MOD_night", "LST_MYD_day", "LST_MYD_night")
is.na(joineddataset[v_LST]) <-  joineddataset[v_LST] < 150
joineddataset$N_LST = rowSums(!is.na(joineddataset[v_LST]))

# Get valid IST 
v_IST = c("MOD29P1D", "MOD29P1N", "MYD29P1D", "MYD29P1N")
is.na(joineddataset[v_IST]) <-  joineddataset[v_IST] < 210
is.na(joineddataset[v_IST]) <-  joineddataset[v_IST] > 410
joineddataset$N_IST = rowSums(!is.na(joineddataset[v_IST]))


joineddataset$LST = rowMeans(joineddataset[v_LST], na.rm = TRUE)
joineddataset$IST = rowMeans(joineddataset[v_IST], na.rm = TRUE)


#Predictor variables 
Predictor_variables = read.table("/Users/Eva/Documents/PhD/R/AntAIR2/Data/Predictor values/Predictor_variables.txt", header=TRUE, sep="," )
joineddataset$DOY = yday(as.Date(joineddataset$Date))

joineddataset_full <- merge(joineddataset, Predictor_variables, by = c('AWS_data.Name','DOY'))

# Change to celsius 
joineddataset_full$LST = joineddataset_full$LST - 273.15
joineddataset_full$IST = joineddataset_full$IST - 273.15


# Remove AWS
joineddataset_full = joineddataset_full  %>% filter(AWS_data.Name != "Modesta")
joineddataset_full = joineddataset_full  %>% filter(AWS_data.Name != "Giulia")


# Make one dataset from filtered values 

#Filter quality only pixel with good quality in all 4 dataset 
joineddataset_LST = joineddataset_full %>% filter(QA_MOD_day < 16, QA_MOD_night < 16, QA_MYD_day < 16, QA_MYD_night < 16, 
                                                  QA_MOD_day !=3, QA_MOD_night !=3, QA_MYD_day !=3, QA_MYD_night !=3,
                                                  QA_MOD_day !=2, QA_MOD_night !=2, QA_MYD_day !=2, QA_MYD_night !=2,
                                                  N_LST  == 4, N_measurments >23,T_air_daily>-200)

#joineddataset_LST = joineddataset_full %>% filter(N_measurments >23,T_air_daily>-200, N_LST >0)

joineddataset_LST$Skin = joineddataset_LST$LST   # Set Skin to only LST values 

MODIS_AWS_temp = joineddataset_LST



# IST selection -----------------------------------------------------------
#Filter quality wiht good quality in all 4 datasets 

joineddataset_IST = joineddataset_full %>% filter(N_IST > 0, N_LST ==0, T_air_daily>-150, N_measurments>23)
joineddataset_IST$Skin = joineddataset_IST$IST

# remove stations on land pixel
joineddataset_IST = joineddataset_IST  %>% filter(AWS_data.Name != "CASEY")
joineddataset_IST = joineddataset_IST  %>% filter(AWS_data.Name != "MAWSON")
joineddataset_IST = joineddataset_IST  %>% filter(AWS_data.Name != "cbd", AWS_data.Name != "mpt", AWS_data.Name != "mp2", AWS_data.Name != "hug",  AWS_data.Name != "bpt",)
joineddataset_IST = joineddataset_IST  %>% filter(AWS_data.Name != "Alessandra", AWS_data.Name != "Eneide", AWS_data.Name != "Arelis" , AWS_data.Name != "Maria")

# Add coordinates to info
joineddataset_IST_coord = merge(joineddataset_IST, Coord_AWS2, by = 'AWS_data.Name')

joineddataset_IST_summer1 = joineddataset_IST_coord %>% filter(N_IST > 0, !between(DOY, 45, 300), Lat<(-75))
joineddataset_IST_winter = joineddataset_IST_coord %>% filter(N_IST > 1, between(DOY, 45, 300), Lat<(-75))


joineddataset_IST2 = joineddataset_IST_coord %>% filter(!is.na(MOD29P1D), !is.na(MOD29P1N), is.na(MYD29P1D),is.na(MYD29P1N), Lat>-75)
joineddataset_IST3 = joineddataset_IST_coord %>% filter(is.na(MOD29P1D), is.na(MOD29P1N), !is.na(MYD29P1D),!is.na(MYD29P1N), Lat>-75)
joineddataset_IST4 = joineddataset_IST_coord%>% filter(is.na(MOD29P1D), !is.na(MOD29P1N), !is.na(MYD29P1D),is.na(MYD29P1N), Lat>-75)
joineddataset_IST5 = joineddataset_IST_coord %>% filter(!is.na(MOD29P1D), is.na(MOD29P1N), is.na(MYD29P1D),!is.na(MYD29P1N), Lat>-75)
joineddataset_IST6 = joineddataset_IST_coord %>% filter(!is.na(MOD29P1D), !is.na(MOD29P1N), !is.na(MYD29P1D),!is.na(MYD29P1N), Lat>-75)

joineddataset_IST_corr= rbind(joineddataset_IST_winter, joineddataset_IST_summer1 ,joineddataset_IST2, joineddataset_IST3, joineddataset_IST4,joineddataset_IST5,joineddataset_IST6 )


joineddataset_IST = joineddataset_IST_corr
joineddataset_IST = joineddataset_IST %>% filter(Skin<0)



# IST and LST together Var: 0 = LST 1 = IST
#MODIS_AWS_temp = rbind(joineddataset_IST, joineddataset_LST)


# LM LST ------------------------------------------------------------

# Dataset for LM 

MODIS_AWS_temp$Bedmap[is.na(MODIS_AWS_temp$Bedmap)] <- 1

MODIS_AWS_temp$Year = as.numeric(substr(MODIS_AWS_temp$Date,1,4))


MODIS_AWS_temp_clean = data.frame(MODIS_AWS_temp$AWS_data.Name, MODIS_AWS_temp$DOY,
                                  MODIS_AWS_temp$T_air_daily, MODIS_AWS_temp$DEM,
                                  MODIS_AWS_temp$Bedmap,
                                  MODIS_AWS_temp$Solar_altitude_min, MODIS_AWS_temp$Solar_altitude_max,
                                  MODIS_AWS_temp$Solar_Daylight,MODIS_AWS_temp$Shadow,
                                  MODIS_AWS_temp$Skin, MODIS_AWS_temp$Year, MODIS_AWS_temp$N_LST)

colnames(MODIS_AWS_temp_clean ) = c("AWS_data.Name", "DOY", "T_air_daily", "DEM", "Bedmap",
                                           "Solar_altitude_min", "Solar_altitude_max",
                                           "Solar_Daylight", "Shadow",
                                           "Skin", "Year", "N_measurments")


# Temporal validation
Years_val = seq(2003,2021, by=3)

MODIS_AWS_temp_test  = MODIS_AWS_temp_clean  %>% filter(Year %in% Years_val)
MODIS_AWS_temp_train = MODIS_AWS_temp_clean  %>% filter(!Year %in% Years_val)

lmModel <- lm(T_air_daily ~ Skin, data = MODIS_AWS_temp_train)
summary(lmModel)


## save this model
save(lmModel, file = "/Users/Eva/Documents/PhD/R/AntAIR2/Models/lmModel.rda")
#load("/Users/Eva/Documents/PhD/R/AntAIR2/Models/lmModel.rda")


MODIS_AWS_temp_test$PreditedSkin_LM <- predict(lmModel, MODIS_AWS_temp_test)
MODIS_AWS_temp$PreditedSkin_LM <- predict(lmModel, MODIS_AWS_temp)


RMSE = RMSE(MODIS_AWS_temp_test$PreditedSkin_LM , MODIS_AWS_temp_test$T_air_daily)
MAE = MAE(MODIS_AWS_temp_test$PreditedSkin_LM , MODIS_AWS_temp_test$T_air_daily)
R2 = R2(MODIS_AWS_temp_test$PreditedSkin_LM , MODIS_AWS_temp_test$T_air_daily)
MODIS_AWS_temp_test$AbsE = abs(MODIS_AWS_temp_test$T_air_daily - MODIS_AWS_temp_test$PreditedSkin_LM)
MODIS_AWS_temp_test$E = MODIS_AWS_temp_test$T_air_daily - MODIS_AWS_temp_test$PreditedSkin_LM




# LM for IST --------------------------------------------------------------


# Dataset for LM 

joineddataset_IST$Bedmap[is.na(joineddataset_IST$Bedmap)] <- 1

joineddataset_IST$Year = as.numeric(substr(joineddataset_IST$Date,1,4))


joineddataset_IST_clean = data.frame(joineddataset_IST$AWS_data.Name, joineddataset_IST$DOY,
                                     joineddataset_IST$T_air_daily, joineddataset_IST$DEM,
                                     joineddataset_IST$Bedmap,
                                     joineddataset_IST$Solar_altitude_min, joineddataset_IST$Solar_altitude_max,
                                     joineddataset_IST$Solar_Daylight,joineddataset_IST$Shadow,
                                     joineddataset_IST$Skin, joineddataset_IST$Year, joineddataset_IST$N_IST)

colnames(joineddataset_IST_clean ) = c("AWS_data.Name", "DOY", "T_air_daily", "DEM", "Bedmap",
                                    "Solar_altitude_min", "Solar_altitude_max",
                                    "Solar_Daylight", "Shadow",
                                    "Skin", "Year", "N_measurments")


Years_val = seq(2003,2021, by=3)

joineddataset_IST_temp_test  = joineddataset_IST_clean  %>%  filter(Year %in% Years_val)
joineddataset_IST_temp_train= joineddataset_IST_clean  %>% filter(!Year %in% Years_val)


lmModel_IST <- lm(T_air_daily ~ Skin, data = joineddataset_IST_temp_train)
summary(lmModel_IST)

save(lmModel_IST, file = "lmModel_IST.rda")
#load("/Users/Eva/Documents/PhD/R/AntAIR2/Models/lmModel_IST.rda")

joineddataset_IST_temp_test$PreditedSkin_LM <- predict(lmModel_IST, joineddataset_IST_temp_test)
joineddataset_IST$PreditedSkin_LM <- predict(lmModel_IST, joineddataset_IST)


RMSE_IST = RMSE(joineddataset_IST_temp_test$PreditedSkin_LM , joineddataset_IST_temp_test$T_air_daily)
MAE_IST = MAE(joineddataset_IST_temp_test$PreditedSkin_LM , joineddataset_IST_temp_test$T_air_daily)
R2_IST = R2(joineddataset_IST_temp_test$PreditedSkin_LM , joineddataset_IST_temp_test$T_air_daily)


joineddataset_IST_temp_test$AbsE = abs(joineddataset_IST_temp_test$T_air_daily - joineddataset_IST_temp_test$PreditedSkin_LM)
joineddataset_IST_temp_test$E = joineddataset_IST_temp_test$T_air_daily - joineddataset_IST_temp_test$PreditedSkin_LM
