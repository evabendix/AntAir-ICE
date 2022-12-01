# LST and Quality flag daily GeoTIFF for Antarctica
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


aoi= "-78.72478011957196,-62.93664367444223,-130.4718129774105,-62.83645212475613,169.36868038398484,-64.88505417081656,133.85029727272888,-52.36289148691665,97.96085767261906,-55.05207902981221,50.21863761805126,-55.17233265479056,7.835846320638906,-60.75924590216369,-56.733650396154104,-58.81842738297898,-78.72478011957196,-62.93664367444223"


# Define products
products <- c("MOD11A1","MYD11A1")
collection = 6

type = c("day", "night")
path_data= "/scratch/tmp/bendixni/AntAIR2/Data/hdf"
path= "/scratch/tmp/bendixni/AntAIR2/Data"
path_project = "/home/b/bendixni/AntAir2"
temp_dir = tempdir()


Dates = start

while (Dates <= end){
  theDate = format((Dates),"%d-%m-%Y")

  names = cbind("MOD_Day_QA", "MOD_Night_QA", "MYD_Day_QA", "MYD_Night_QA")
  for (h in 1:length(products)){
    product=products[h]
    print(product)
    
    LST_dir = paste0(path_data, "/LST_hdf/", products[h],"_",theDate, sep="")
    
    DOY = lubridate::yday(Dates)
    
    if (dir.exists(LST_dir)){

      setwd(paste0(LST_dir,"/hdf",sep=""))
      
      HDF_files = list.files(paste0(LST_dir,"/hdf", sep=""))
      
      source_python(paste0(path_project,"/Python_code/conv_LST_day.py", sep=""))
      
      if (length(HDF_files)>0){
        
        #coverts to tiff daytime
        for (i in 1:length(HDF_files)){
          conv_MODIS(HDF_files[i])
        }
        # Merge tiffs to one mosaik 
        all_my_rasts = list.files(pattern="*LST_Day_1km.tif")
        name1 = paste0(product,"_", theDate,type[1],".tif", sep="")
        mosaic_rasters(gdalfile=all_my_rasts,
                       dst_dataset=name1,
                       et=0.001)
        
        
        
        # move to another folder 
        file.rename(from=paste0(LST_dir,"/hdf/",name1,sep=""), 
                    to=paste0(LST_dir,"/",name1,sep=""))
        
        # QA Day
        source_python(paste0(path_project,"/Python_code/conv_LST_QC_Day.py",sep=""))
        dir.create(paste0(LST_dir,"/QA",sep=""))
        QA_path = paste0(LST_dir,"/QA",sep="")

          
        #coverts to tiff daytime Qa
        for (i in 1:length(HDF_files)){
          conv_MODIS(HDF_files[i])
        }
        # Merge tiffs to one QA mosaik 
        all_my_rasts = list.files(pattern="*QC_Day.tif")
        name1 = paste0(product,"_",theDate,"QC_Day.tif", sep="")
        mosaic_rasters(gdalfile=all_my_rasts,
                       dst_dataset=name1,
                       et=0.001, force_ot = "Int16" )
        
        # move to another folder 
        
        file.rename(from=paste0(LST_dir,"/hdf/",name1,sep=""), 
                    to=paste0(QA_path,"/",name1,sep=""))
        
        gc()
        
        # Night data 
        source_python(paste0(path_project,"/Python_code/conv_LST_night.py",sep=""))
        # Converts to nighttime tiff
        for (ii in 1:length(HDF_files)){
          conv_MODIS(HDF_files[ii])
        }
        
        # Merge 
        all_my_rasts = list.files(pattern="*LST_Night_1km.tif")
        name2 = paste0(product,"_",theDate,type[2],".tif", sep="")
        mosaic_rasters(gdalfile=all_my_rasts,
                       dst_dataset=name2,
                       et=0.001)

        file.rename(from=paste0(LST_dir,"/hdf/",name2,sep=""), 
                    to=paste0(LST_dir,"/",name2,sep=""))

        
        # QA Night
        source_python(paste0(path_project,"/Python_code/conv_LST_QC_Night.py",sep=""))
        
        #coverts to tiff daytime Qa
        for (i in 1:length(HDF_files)){
          conv_MODIS(HDF_files[i])
        }
        # Merge tiffs to one mosaik 
        all_my_rasts = list.files(pattern="*QC_Night.tif")
        name2 = paste0(product,"_",theDate,"QC_Night.tif", sep="")
        mosaic_rasters(gdalfile=all_my_rasts,
                       dst_dataset=name2,
                       et=0.001,
                       force_ot = "Int16")
        
        # move to another QA folder 
        file.rename(from=paste0(LST_dir,"/hdf/",name2,sep=""), 
                    to=paste0(QA_path,"/",name2,sep=""))
        
        # transform to CRS and move
        setwd(LST_dir)
        r_files = list.files(pattern="*.tif") 
        
        for (fi in 1:2){ 
          name_out = paste0("proj",r_files[fi], sep="")
          
          gdalwarp(r_files[fi],name_out,
                   s_srs = "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs" ,
                   t_srs = "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
                   et = 0.0012,
                   tr = c(1000,1000),
                   ot = "Int16", 
                   r="near") # target resolution to match 1000x1000m
          
          # Moves merges and removes all other files 
          file.rename(from=paste0(LST_dir,"/",name_out,sep=""), 
                      to=paste0(path,"/LST/",name_out,sep=""))
          
        }
        
        gc()
        
        # transform QA to CRS and move
        setwd(QA_path)
        QA_files = list.files(pattern = "*.tif")
        
        for (fi in 1:2){
          name_out = paste0("QA_",QA_files[fi], sep="")
          
          # Make CRS transformation 
          
          gdalwarp(QA_files[fi],name_out,
                   s_srs = "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs" ,
                   t_srs = "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
                   et = 0.0012,
                   tr = c(1000,1000),
                   ot = "Int16",
                   r="near") # target resolution to match 1000x1000m
          
          # Moves merges and removes all other files 
          file.rename(from=paste0(QA_path,"/",name_out,sep=""), 
                      to=paste0(path,"/QA/",name_out,sep=""))
        }
        #Deletes all other files 
        fold <- paste0(LST_dir,"/hdf",sep="")
        
        # get all files in the directories, recursively
        f <- list.files(fold, pattern= "*.tif", include.dirs = F, full.names = T, recursive = T)
        
        file.remove(f)
        
        # get all files in the directories, recursively
        f2 <- list.files(QA_path, include.dirs = F, full.names = T, recursive = F)
        
        file.remove(f2)  

      
    } else {
      print("Dir does not exists!")
    }
    }

  }
  gc()
  
    
  # New Date
  Dates <- Dates + 1 
  
  
  gc()
  temp_files = list.files(temp_dir, full.names = T, recursive = T)
  file.remove(temp_files)
}


