#IST daily GeoTIFF for Antarctica
rm(list=ls())

library(raster)
library(reticulate)
library(gdalUtils)
library(stringr)


# Define python
use_python("/Applic.HPC/Easybuild/skylake/2020a/software/Python/3.8.2-GCCcore-9.3.0/bin/python", required=T) #/Users/Eva/opt/anaconda3/envs/myenv/bin/python", required = T)
# Check the version of Python.
py_config()


start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2021",format="%d-%m-%Y")

# Define products
collection = 6

type = c("day", "night")
path_data= "/scratch/tmp/bendixni/AntAIR2/Data/hdf"
path= "/scratch/tmp/bendixni/AntAIR2/Data"
path_project = "/home/b/bendixni/AntAir2"
temp_dir = tempdir()

DDates <- seq(start, end, by=1)

for(i in 1:length(Ddates)){
  Dates = DDates[i]
  theDate = format((Dates),"%d-%m-%Y")
  
  products_IST= c("MOD29P1D","MOD29P1N","MYD29P1D","MYD29P1N")
  
  for (h in 1:length(products_IST)){
   product=products_IST[h]
   
   source_python(paste0(path_project,"/Python_code/Conv_IST.py",sep=""))
   IST_dir = paste0(path_data, "/IST_hdf/", product,"_",theDate, sep="")
   
   setwd(IST_dir)
   
   HDF_files=list.files(pattern="*.hdf")
   
   if(length(HDF_files) == 0) {
     print("no_data")
     
   } else{
     # Converts to  tiff
     for (ii in 1:length(HDF_files)){
       conv_MODIS(HDF_files[ii])
       
     }
     # Merge
     all_my_rasts = list.files(pattern="*.Ice_Surface_Temperature.tif")
     name_IST = paste0(product,"_", theDate,".tif", sep="")
     mosaic_rasters(gdalfile=all_my_rasts,
                    dst_dataset=name_IST,
                    et=0.001)
    
     
     
     name_out = paste0( "proj",product,"_", theDate,".tif", sep="")
     
     gdalwarp(name_IST,name_out,
              s_srs = "+proj=laea +lat_0=-90 +lon_0=0 +x_0=0 +y_0=0 +R=6371228 +units=m +no_defs" ,
              t_srs = "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
              et = 0.0012,
              tr = c(1000,1000),
              ot = "Int16",
              r="near") # target resolution to match 1000x1000m
     
     # Moves merges and removes all other files 
     file.rename(from=paste0(IST_dir,"/",name_out,sep=""), 
                 to=paste0(path,"/IST/",name_out,sep=""))
   
     fold <- IST_dir
     f <- list.files(fold, pattern= "*.tif", include.dirs = F, full.names = T, recursive = T)
     file.remove(f)
    
   }
   
  
  }

    
  gc()
  temp_files = list.files(temp_dir, full.names = T, recursive = T)
  file.remove(temp_files)
}






