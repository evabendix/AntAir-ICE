#Compile final dataset to daily GeoTIFF with two layers

library(raster)
library(terra)
library(stringr)
library(dplyr)
library(lubridate)

data_path = "//file.canterbury.ac.nz/Research/AntarcticaFoehnWarming/AntAir v.2/"                    # IST
path_out = "//file.canterbury.ac.nz/Research/AntarcticaFoehnWarming/AntAir v.2/Final"   # IST 


start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2019",format="%d-%m-%Y")

Dates <- seq(start, end, by=1)

rgdal::setCPLConfigOption("GDAL_PAM_ENABLED", "FALSE")

for(x in 1:length(Dates)){

  date = format((Dates[x]),"%d-%m-%Y")
  
  LST = rast(paste0(data_path,"/AntAir_land/AntAir_",date,".tif"))
  LST_N = rast(paste0(data_path,"/N/Sum_scenes",date,".tif"))

  IST = rast(paste0(data_path,"/AntAir_ICE/AntAir_",date,"IST.tif"))
  IST_N = rast(paste0(data_path,"/N/Sum_scenesIST",date,".tif"))
  
  LST_large = extend(LST,IST,snap="in")
  LST_N_large = extend(LST_N,IST_N,snap="in")
  LST_N_large[LST_N_large == 0] = NA
  
  IST_re = resample(IST, LST_large, method = "bilinear" )
  IST_N_re = resample(IST_N, LST_N_large, method = "near" )
  IST_N_re[ IST_N_re == 0] = NA
  
  
  AntAir_Temp = raster::merge(raster(LST_large),raster(IST_re))
  AntAir_Temp = round(AntAir_Temp*10, digits =0)
  AntAir_N = raster::merge(raster(LST_N_large),raster(IST_N_re))
  
  AntAir_Temp[is.na(AntAir_N)] = NA
  
  AntAir= brick(AntAir_Temp, AntAir_N)
  AntAir@data@names = c("AirTemperature","N_scenes")
  
  
  DOY = yday(as.Date(date, format="%d-%m-%Y"))
  Year = substr(date,7,11)
  
  name_end = paste0(path_out,"/AntAir_ICE_",Year,"_",str_pad(DOY,width=3,side="left", pad = "0"),".tif")
  writeRaster(AntAir, name_end, datatyper = "INT1S", gdal=c("COMPRESS=LZW"), overwrite=TRUE)  
  
  
}
