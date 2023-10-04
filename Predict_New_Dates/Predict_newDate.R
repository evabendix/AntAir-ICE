library(raster)
library(rts)
library(MODIStsp)
library(terra)
library(luna)
library(lubridate)
library(stringr)
library(reticulate)
library(gdalUtils)



path = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path)

#Define paths
data_path = paste0(path, "/Data", sep="")
python_path = paste0(path, "/Python_code", sep="")

temp_dir = tempdir()


# Define your python enviroment
use_python("/Users/Eva/opt/anaconda3/envs/myenv/bin/python", required=T) 
# Check the version of Python.
py_config()

# Insert username and password from https://urs.earthdata.nasa.gov
username1=""
password1=""

setNASAauth(username=username1, password=password1, update=TRUE)


ANT = getData(country = "ATA", level = 0 )
aoi= "-78.72478011957196,-62.93664367444223,-130.4718129774105,-62.83645212475613,169.36868038398484,-64.88505417081656,133.85029727272888,-52.36289148691665,97.96085767261906,-55.05207902981221,50.21863761805126,-55.17233265479056,7.835846320638906,-60.75924590216369,-56.733650396154104,-58.81842738297898,-78.72478011957196,-62.93664367444223"


#Define start and end date for AntAir ICE extraction
start <- "2023-01-13"
end <- "2023-01-14"

source("./Download_functions.R") #Load function 
#Downloade MODSI LST
MODIS_LST_down(start, end, data_path, username1,password1, ANT)
#Downloade MODSI IST
MODIS_IST_down(start, end, data_path,username1, password1, aoi)

#Merge and convert to raster 
Merge_LST(start, end, path)

#Merge and convert to raster 
Merge_IST(start, end, path)
setwd(path)

# Combine MODIS IST and LST output to AntAIr ICE 
AntAir_ICE_finalisation(start,end,path) 

