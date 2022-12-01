### Cloud filter LST
# Needs to be done for MOD day/night and MYD day/night 

library(raster)
library(sf)
library(stringr)
library(dplyr)
library(lubridate)

Data_path = "/scratch/tmp/bendixni/AntAIR2/Data/LST"
path_out = "/scratch/tmp/bendixni/AntAIR2/Data/LST_res/"

start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2021",format="%d-%m-%Y")

# mean and SD for 20 days
Dates <- seq(start, end, by=20)


for(x in 1:(length(Dates)-1)){
  int = seq(Dates[x], Dates[x+1], by=1)
  date = format((int),"%d-%m-%Y")

  
  LST_MOD = list.files(path = Data_path, pattern = paste0("projMOD11A1", "_", date, ".*day.tif", sep="", collapse = "|"), full.names = T)
  
  # get on same extent 
  ext = raster("/scratch/tmp/bendixni/AntAIR2/Data/LST/projMOD11A1_01-01-2003day.tif")

  
  LST_brick = brick(lapply(LST_MOD,raster))
  LST_brick = raster::reclassify(LST_brick, c(-1,0, NA))
  
  
  # Calculate SD and mean 
  mean_brick = calc(LST_brick, fun = function(X) {mean(X, na.rm = T)})
  sd_brick = calc(LST_brick, fun = function(X) {sd(X, na.rm = T)})
  lower_threshold <- mean_brick - (sd_brick * 2)
  gc()
  
  
  # Remove -2*SD
  for (i in 1:length(LST_MOD)){
    layer= raster(LST_MOD[i])
    layer=raster::reclassify(layer, c(-1,0, NA)) # Mask for values outside the temperature range 
    layer[layer < lower_threshold] = NA
    
    name_end = paste0(path_out,substr(LST_MOD[i],40,64),".tif", sep="")
    writeRaster(layer, name_end, format="GTiff", options=c("COMPRESS=NONE"), overwrite=TRUE)  
    
  }
  gc()
  rm(mean_brick,sd_brick,lower_threshold, LST_brick)

}

