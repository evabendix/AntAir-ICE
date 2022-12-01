### Number of LST data in AntAir ICE

library(raster)
library(stringr)
library(dplyr)
library(lubridate)

Data_path = "/scratch/tmp/bendixni/AntAIR2/Data/IST"
path_out = "/scratch/tmp/bendixni/AntAIR2/Data/QA/"


start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2021",format="%d-%m-%Y")


Dates <- seq(start, end, by=1)


for(x in 1:length(Dates)){
  
  date = format((Dates[x]),"%d-%m-%Y")
  
  IST_MOD = list.files(path = Data_path, pattern = paste0("projMOD29P1", ".*_", date, ".tif", sep=""), full.names = T)
  IST_MYD = list.files(path = Data_path, pattern = paste0("projMYD29P1", ".*_", date, ".tif", sep=""), full.names = T)
  
  
  IST_files = c(IST_MOD, IST_MYD)
  
  
  r= list()
  for (k in 1:length(IST_files)){ 
    ras_imp=raster(IST_files[k])
    
    ras_imp[ras_imp < 210] = NA
    ras_imp[ras_imp >= 273] = NA
    ras_imp[ras_imp == 0] = NA
    
    ras_imp[!is.na(ras_imp[])] <- 1
    r= c(r,ras_imp)
    
  }
  # Calculate mean 
  mosaic_sum = do.call(mosaic, c(r, fun = sum, na.rm = T, tolerance=10))
  
  # Write raster 
  name_end = paste0(path_out,"Sum_scenesIST", date,".tif", sep="")
  writeRaster(mosaic_sum, name_end, format="GTiff", options=c("COMPRESS=NONE"), overwrite=TRUE)  
}


