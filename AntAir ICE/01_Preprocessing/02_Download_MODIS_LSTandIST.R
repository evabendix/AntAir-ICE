# Download LST and IST 

# LST for antarctica
rm(list=ls())

library(sf)
library(raster) 
library(reticulate)
library(gdalUtils)
library(tmap)
library(RGISTools)
library(terra)
library(rts)
library(stringr)

# Define python
use_python("/Applic.HPC/Easybuild/skylake/2020a/software/Python/3.8.2-GCCcore-9.3.0/bin/python", required=T)
# Check the version of Python.
py_config()


start = as.Date("01-01-2003",format="%d-%m-%Y")
end  = as.Date("31-12-2021",format="%d-%m-%Y")


aoi= "-78.72478011957196,-62.93664367444223,-130.4718129774105,-62.83645212475613,169.36868038398484,-64.88505417081656,133.85029727272888,-52.36289148691665,97.96085767261906,-55.05207902981221,50.21863761805126,-55.17233265479056,7.835846320638906,-60.75924590216369,-56.733650396154104,-58.81842738297898,-78.72478011957196,-62.93664367444223"

#Define AOI
ANT = getData(country = "ATA", level = 0 )


# Define products
products <- c("MOD11A1","MYD11A1")
collection = 6

type = c("day", "night")
path_data= "/scratch/tmp/bendixni/AntAIR2/Data/hdf"
path= "/scratch/tmp/bendixni/AntAIR2/Data"
path_project = "/home/b/bendixni/AntAir2"
temp_dir = tempdir()

setNASAauth(username="XXX",password="XXX")
#Dates = start

trim <- function (x) {
  x <- strsplit(x, "")[[1]]
  paste(x[x != " "], collapse = "")
}

for(i in 1:length(empty_dates[,1])){
#for(i in 1:2){
  Date = substr(empty_dates[i,], 9, 18)
  theDate = Date

  names = cbind("MOD_Day_QA", "MOD_Night_QA", "MYD_Day_QA", "MYD_Night_QA")
  setwd(path)
  for (h in 1:length(products)){
    product=products[h]
    print(product)
    
    DD = paste0(substr(Date,7,10),".",substr(Date,4,5),".",substr(Date,1,2))
 
    LST_dir = paste0(path_data, "/LST_hdf/", products[h],"_",theDate, sep="")
    
    setwd(LST_dir)
    
    HDF_list = list.files(pattern = "*.hdf", recursive = T)
    file.remove(HDF_list)

    # Search for available products 
    getMODIS(product,h=c(13,14,15,16,17,18,19,20,21,22,23,24,25,26,27), v=c(14,15,16,17), version='006',dates=DD, forceReDownload=TRUE, ncore='auto')
    

    } 

  gc()
  
  ##################################################
  # IST 
  
  products_IST= c("MOD29P1D","MOD29P1N","MYD29P1D","MYD29P1N")

  for (l in 1:length(products_IST)){
    product_IST=products_IST[l]
    # Downloade files 
    start_time =paste0(substr(theDate,7,10),"-",substr(theDate,4,5), "-",substr(theDate,1,2), "T00:00:00Z", sep="")
    end_time=paste0(substr(theDate,7,10),"-",substr(theDate,4,5), "-",substr(theDate,1,2), "T23:59:00Z", sep="")
    
    dir.create(paste0(path_data, "/IST_hdf/", products_IST[l],"_",theDate, sep=""))
    IST_dir = paste0(path_data, "/IST_hdf/", products_IST[l],"_",theDate, sep="")
    
    
    setwd(IST_dir)
    source_python(paste0(path_project,"/Python_code/MODIS_Download_IST_fun.py",sep=""))
    
    download_MODIS_function(product_IST, start_time, end_time, aoi)
    xml_files=list.files(pattern="*.xml")
    file.remove(xml_files)
  }
    
  # New Date
  Dates <- Dates + 1 
  
  
  gc()
  temp_files = list.files(temp_dir, full.names = T, recursive = T)
  file.remove(temp_files)
}


