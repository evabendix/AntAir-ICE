#Apply model for years 2003-2021 LST

library(raster)
library(stringr)
library(dplyr)
library(lubridate)


Data_path = "/scratch/tmp/bendixni/AntAIR2/Data/LST_res"
path_out = "/scratch/tmp/bendixni/AntAIR2/Data/LST_Mean/"



start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2021",format="%d-%m-%Y")


Dates <- seq(start, end, by=1)


for(x in 1:length(Dates)){
  date = format((Dates[x]),"%d-%m-%Y")
  
  LST_MOD = list.files(path = Data_path, pattern = paste0("projMOD11A1", "_", date, ".*.tif", sep=""), full.names = T)
  LST_MYD = list.files(path = Data_path, pattern = paste0("projMYD11A1", "_", date, ".*.tif", sep=""), full.names = T)
  LST_files = c(LST_MOD, LST_MYD)
  
  print(LST_files)
  
  r= list()
  
  for (k in 1:length(LST_files)){ 
    ras_imp=raster(LST_files[k])
    ras_imp=raster::reclassify(ras_imp, c(-1, 150, NA)) # Mask for values outside the temperatur range 
    
    r= c(r,ras_imp)
  }
  # Calculate mean 
  mosaic_mean = do.call(mosaic, c(r, fun = mean, na.rm = T, tolerance=10))
  mosaic_mean = round(((mosaic_mean - 273.15 )), digits = 2) 
  

  names(mosaic_mean) =  "Skin"
  
  load("/home/b/bendixni/AntAir2/R_code/lmModel.rda")
  
  p <- predict(mosaic_mean, lmModel)
  
  # Write raster 
  name_end = paste0(path_out,"AntAir_", date,".tif", sep="")
  writeRaster(p, name_end, format="GTiff", options=c("COMPRESS=NONE"), overwrite=TRUE)  
}





