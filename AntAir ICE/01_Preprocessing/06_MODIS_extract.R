#Extract LST and IST 

rm(list=ls())

library(sf)
library(raster)
library(dplyr)
library(gdalUtils)
library(stringr)

#Define start and end date
start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2021",format="%d-%m-%Y")


path= "/scratch/tmp/bendixni/AntAIR2/Data"
path_project = "/home/b/bendixni/AntAir2"
temp_dir = tempdir()


#load station coordinates
AWS_data = read.table(file = "/scratch/tmp/bendixni/AntAIR2/Stations_Antarctica_all.txt", 
                      header = T, sep =",",fill=TRUE)

Coord_AWS = data.frame(AWS_data$Long,AWS_data$Lat )
AWS_coord_Sp = SpatialPointsDataFrame(coords = Coord_AWS, data = Coord_AWS,
                                   proj4string = crs("+init=epsg:4326"))
AWS_coord = spTransform(AWS_coord_Sp, CRSobj = CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))

# Dataframe for daily data
Surface_temp = data.frame(AWS_data$Name)
# Dataframe for all data
Surface_temperature_total = data.frame()  

DDates <- seq(start, end, by=1)

for(i in 1:length(DDates)){
  Dates = DDates[i]
  theDate = format((Dates),"%d-%m-%Y")
  


  Surface_temp$Date = theDate
  #Temp = data.frame()
  
  #LST 
  
  LST_MOD_day = paste0(path, "/LST_res/proj", "MOD11A1_",theDate, "day.tif", sep="")
  LST_MOD_night = paste0(path, "/LST_res/proj", "MOD11A1_",theDate, "night.tif", sep="")
  
  LST_MYD_day = paste0(path, "/LST_res/proj", "MYD11A1_",theDate, "day.tif", sep="")
  LST_MYD_night = paste0(path, "/LST_res/proj", "MYD11A1_",theDate, "night.tif", sep="")
  
  #QA
  MOD_QA_day_dir = paste0(path, "/QA/QA_MOD11A1_", theDate, "QC", "_Day.tif")
  MOD_QA_night_dir = paste0(path, "/QA/QA_MOD11A1_", theDate, "QC", "_Night.tif")
  
  MYD_QA_day_dir = paste0(path, "/QA/QA_MYD11A1_", theDate, "QC", "_Day.tif")
  MYD_QA_night_dir = paste0(path, "/QA/QA_MYD11A1_", theDate, "QC", "_Night.tif")
 
  tryCatch(
    {
      Surface_temp$LST_MOD_day = extract(raster(LST_MOD_day), AWS_coord)
      Surface_temp$LST_MOD_night = extract(raster(LST_MOD_night ), AWS_coord)
      Surface_temp$LST_MYD_day = extract(raster(LST_MYD_day), AWS_coord)
      Surface_temp$LST_MYD_night = extract(raster(LST_MYD_night), AWS_coord)
      
      MOD_QA_day = raster(MOD_QA_day_dir)
      MOD_QA_night = raster(MOD_QA_night_dir)
      MYD_QA_day = raster(MYD_QA_day_dir)
      MYD_QA_night = raster(MYD_QA_night_dir)
      
      
      Surface_temp$QA_MOD_day = extract(MOD_QA_day, AWS_coord)
      Surface_temp$QA_MOD_night = extract(MOD_QA_night, AWS_coord)
      Surface_temp$QA_MYD_day = extract(MYD_QA_day, AWS_coord)
      Surface_temp$QA_MYD_night = extract(MYD_QA_night, AWS_coord)
      
      
      products_IST= c("MOD29P1D","MOD29P1N","MYD29P1D","MYD29P1N")
      
      IST_MOD_day = paste0(path, "/IST/proj", "MOD29P1D","_",theDate, ".tif", sep="")
      IST_MOD_night = paste0(path, "/IST/proj", "MOD29P1N","_",theDate, ".tif", sep="")
      
      IST_MYD_day = paste0(path, "/IST/proj", "MYD29P1D","_",theDate, ".tif", sep="")
      IST_MYD_night = paste0(path, "/IST/proj", "MYD29P1N","_",theDate, ".tif", sep="")
      
      IST_MODD = raster(IST_MOD_day)
      Surface_temp$MOD29P1D = extract(IST_MODD, AWS_coord)
      
      IST_MODN = raster(IST_MOD_night)
      Surface_temp$MOD29P1N = extract(IST_MODN, AWS_coord)  
      
      IST_MYDD = raster(IST_MYD_day)
      Surface_temp$MYD29P1D = extract(IST_MYDD, AWS_coord)
      
      IST_MYDN = raster(IST_MYD_night)
      Surface_temp$MYD29P1N = extract(IST_MYDN, AWS_coord)  
      
      
      Surface_temperature_total = bind_rows(Surface_temperature_total, Surface_temp)
      
      #Surface_temperature_total = Surface_temperature_total[rowSums(is.na(Surface_temperature_total[c("LST", "IST")])) < 2L,]
      
      write.table(Surface_temperature_total, "Surface_temperature_total.txt", append = FALSE, sep = ",", dec = ".",
                  row.names = FALSE, col.names = TRUE)
      
      # New Date
      Surface_temp = data.frame(AWS_data$Name)

    },
    #if an error occurs: 
    error=function(error_message) {
      message(paste0("Error", theDate))
      message(error_message)
      return(NA)
    }
  )
  

  gc()
  temp_files = list.files(temp_dir, full.names = T, recursive = T)
  file.remove(temp_files)
}
