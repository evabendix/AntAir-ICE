# Daily average of air temperature measured in Automatic Weather Stations 

library(stringr)
library(dplyr)
library(lubridate)
library(tidyr)
library(splitstackshape)



# Australian AWS
threshold = 40

setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/AUS_AWS")
AWS_path="~/Documents/PhD/R/AntAIR2/Data/AWS_data/AUS_AWS"

AWS = list.files(path=AWS_path, full.names = F, recursive = F)


for (I in 1:length(AWS)){
  name = paste0(str_sub(AWS[I],1,-5))
  AWS_data = read.table(file = AWS[I], header = T, sep =",")
  
  #Define Date
  date = paste0(AWS_data$Year.Month.Day.Hour.Minutes.in.YYYY.2,"/",AWS_data$MM.2,"/",AWS_data$DD.2)
  s_1 = as.Date(date,format='%Y/%m/%d')
  AWS_data$Date = s_1
  
  #number of measutments by day
  AWS_data = AWS_data %>% drop_na(Air.Temperature.in.degrees.C)
  AWS_mes = aggregate(cbind(count = Air.Temperature.in.degrees.C) ~ Date, 
                      data = AWS_data, 
                      FUN = function(x){NROW(x)})
  
  
  # Group by date and mean 
  AWS_mean = aggregate(AWS_data$Air.Temperature.in.degrees.C, list(AWS_data$Date), mean)
  colnames(AWS_mean) = c("Date_UTC", "T_air_daily")
  
  #Add station 
  AWS_mean$Station=name
  AWS_mean$N_measurments =AWS_mes$count  
  
  AWS_mean = AWS_mean[c("Station", "Date_UTC", "T_air_daily", "N_measurments")]
  # Remove if not measurements all 24 hours 
  AWS_mean = AWS_mean[AWS_mean$N_measurments > threshold, ]
  
  
  # Make -txt file and move it 
  write.table(AWS_mean, paste0(name,"_mean.txt"), append = FALSE, sep = ",", dec = ".",
              row.names = FALSE, col.names = TRUE)
  
  file.rename(from=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/AUS_AWS/",paste0(name,"_mean.txt"),sep=""), 
              to=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean/",paste0(name,"_mean.txt"),sep=""))
}




# Italy AWS 
threshold = 20
setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Italy_AWS")
AWS_path="~/Documents/PhD/R/AntAIR2/Data/AWS_data/Italy_AWS"

AWS = list.files(path=AWS_path, full.names = F, recursive = F)


for (I in 1:length(AWS)){
  name = paste0(str_sub(AWS[I],1,-5))
  AWS_data = read.table(file = AWS[I], header = T, sep =",")
  
  #Define Date
  date = str_sub(AWS_data$DateTime.UTC,1,-6)
  AWS_data$Date = date
  
  AWS_data$Temp = as.numeric(AWS_data$Temp) 
  AWS_data = AWS_data %>% drop_na(Temp)
  
  #number of measutments by day
  AWS_mes = aggregate(cbind(count = Temp) ~ Date, 
                      data = AWS_data, 
                      FUN = function(x){NROW(x)})
  
  
  # Group by date and mean 
  AWS_mean = aggregate(AWS_data$Temp, list(AWS_data$Date), mean)
  colnames(AWS_mean) = c("Date_UTC", "T_air_daily")
  AWS_mean$N_measurments =AWS_mes$count  
  
  #Add station 
  AWS_mean$Station=name
  AWS_mean = AWS_mean[c("Station", "Date_UTC", "T_air_daily", "N_measurments")]
  # Remove if not measurements all 24 hours 
  AWS_mean = AWS_mean[AWS_mean$N_measurments > threshold, ]
  
  # Make .txt file and move it 
  write.table(AWS_mean, paste0(name,"_mean.txt"), append = FALSE, sep = ",", dec = ".",
              row.names = FALSE, col.names = TRUE)
  
  file.rename(from=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Italy_AWS/",paste0(name,"_mean.txt"),sep=""), 
              to=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean/",paste0(name,"_mean.txt"),sep=""))
  
}







# LTER 

threshold = 72
setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/LTER")
AWS_path="~/Documents/PhD/R/AntAIR2/Data/AWS_data/LTER"

AWS = list.files(path=AWS_path, full.names = F, recursive = F)


for (I in 1:length(AWS)){
  name = paste0(str_sub(AWS[I],1,4))
  AWS_data = read.table(file = AWS[I], header = T, sep =",")
  #Define Date
  date = dmy(sapply(strsplit(AWS_data$DATE_TIME, "\\ "), getElement, 1))
  s_1 = as.Date(date,format='%d/%m/%Y')
  AWS_data$Date = s_1
  
  
  AWS_data = AWS_data %>% drop_na(AIRT3M)
  
  #number of measutments by day
  AWS_mes = aggregate(cbind(count = AIRT3M) ~ Date, 
                      data = AWS_data, 
                      FUN = function(x){NROW(x)})
  
  
  
  # Group by date and mean 
  AWS_mean = aggregate(AWS_data$AIRT3M, list(AWS_data$Date), mean)
  colnames(AWS_mean) = c("Date_UTC", "T_air_daily")
  AWS_mean$N_measurments =AWS_mes$count  
  
  #Add station 
  AWS_mean$Station=name
  AWS_mean = AWS_mean[c("Station", "Date_UTC", "T_air_daily", "N_measurments")]
  
  # Remove if not measurements all 24 hours 
  AWS_mean = AWS_mean[AWS_mean$N_measurments > threshold, ]
  
  # Make .txt file and move it 
  write.table(AWS_mean, paste0(name,"_mean.txt"), append = FALSE, sep = ",", dec = ".",
              row.names = FALSE, col.names = TRUE)
  
  file.rename(from=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/LTER/",paste0(name,"_mean.txt"),sep=""), 
              to=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean/",paste0(name,"_mean.txt"),sep=""))
  
}





# NL 
threshold = 20
setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/NL_AWS")
AWS_path="~/Documents/PhD/R/AntAIR2/Data/AWS_data/NL_AWS"

AWS = list.files(path=AWS_path, full.names = F, recursive = F)


for (I in 1:length(AWS)){
  name = paste0(str_sub(AWS[I],1,-5))
  A = read.table(file = AWS[I], header = F, sep =",",colClasses = "character", skip=1)
  AWS_data = do.call(rbind, strsplit(A$V2, "\\,"))
  AWS_data=as.data.frame(AWS_data)

  #Define Date
  AWS_data$V2 = as.numeric(AWS_data$V2) 
  date = as.POSIXct((as.numeric(AWS_data$V2) - 719529)*86400, origin = "1970-01-01", tz = "UTC") # https://stat.ethz.ch/R-manual/R-devel/library/base/html/as.POSIXlt.html
  date = paste0(AWS_data$V1,str_sub(date,5,-10))
  AWS_data$Date = date
  
  
  # removes error values and calculate how many measurments pr day
  AWS_data$V12 = as.numeric(AWS_data$V12) 
  AWS_data= AWS_data[AWS_data$V12 != -9999, ]
  AWS_data= AWS_data[AWS_data$V12 > -4000, ] # Efter fejl på 5000 (se word dokument) ændres dette til -4000
  AWS_mes = aggregate(cbind(count = V12) ~ Date, 
                      data = AWS_data, 
                      FUN = function(x){NROW(x)})
  
  # Group by date and mean 
  AWS_mean = aggregate(AWS_data$V12, list(AWS_data$Date), mean)
  colnames(AWS_mean) = c("Date_UTC", "T_air_daily")
  AWS_mean$N_measurments =AWS_mes$count 
  
  #Add station 
  AWS_mean$Station=name
  AWS_mean = AWS_mean[c("Station", "Date_UTC", "T_air_daily", "N_measurments")]
  
  # Remove if not measurements all 24 hours 
  AWS_mean = AWS_mean[AWS_mean$N_measurments > threshold, ]
  # Make .txt file and move it 
  write.table(AWS_mean, paste0(name,"_mean.txt"), append = FALSE, sep = ",", dec = ".",
              row.names = FALSE, col.names = TRUE)
  
  file.rename(from=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/NL_AWS/",paste0(name,"_mean.txt"),sep=""), 
              to=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean/",paste0(name,"_mean.txt"),sep=""))
  
}



# WU 
threshold = 20
setwd("~/Documents/PhD/R/AntAIR2/Data/AWS_data/UW")
AWS_path="~/Documents/PhD/R/AntAIR2/Data/AWS_data/UW"

AWS = list.files(path=AWS_path, full.names = F, recursive = F)


for (I in 1:length(AWS)){
  name = paste0(str_sub(AWS[I],1,-5))
  AWS_data = read.table(file = AWS[I], header = T, sep =",")
  #Define Date
  date = paste0(AWS_data$Year,"/",AWS_data$Month,"/",AWS_data$Day)
  s_1 = as.Date(date,format='%Y/%m/%d')
  AWS_data$Date = s_1
  
  # removes error values and calculate how many measurments pr day
  AWS_data= AWS_data[AWS_data$Tair != 444, ]
  AWS_mes = aggregate(cbind(count = Tair) ~ Date, 
                         data = AWS_data, 
                         FUN = function(x){NROW(x)})
  
  # Group by date and mean 
  AWS_mean = aggregate(AWS_data$Tair, list(AWS_data$Date), mean)
  colnames(AWS_mean) = c("Date_UTC", "T_air_daily")
  AWS_mean$N_measurments =AWS_mes$count 
  
  #Add station 
  AWS_mean$Station=name
  AWS_mean = AWS_mean[c("Station", "Date_UTC", "T_air_daily", "N_measurments")]
  
  # Remove if not measurements all 24 hours 
  AWS_mean = AWS_mean[AWS_mean$N_measurments > threshold, ]
  # Make .txt file and move it 
  write.table(AWS_mean, paste0(name,"_mean.txt"), append = FALSE, sep = ",", dec = ".",
              row.names = FALSE, col.names = TRUE)
  
  file.rename(from=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/UW/",paste0(name,"_mean.txt"),sep=""), 
              to=paste0("~/Documents/PhD/R/AntAIR2/Data/AWS_data/Stations_Daily_mean/",paste0(name,"_mean.txt"),sep=""))
  
}



