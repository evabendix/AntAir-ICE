##### Functions for downloading MODIS LST and IST product ########


MODIS_LST_down = function(start, end, outputfolder, username, password, area) {
  
  products <- c("MOD11A1","MYD11A1")
  
  for (h in 1:length(products)){
    product=products[h]
    
    mf <- luna::getModis(product, start, end, aoi=area, download = TRUE, version = "061", path=outputfolder, username=username,password=password, overwrite=FALSE)
    
    DDates <- seq(as.Date(start,format="%Y-%m-%d"), as.Date(end,format="%Y-%m-%d"), by=1)
    
    for (i in 1:length(DDates)){
      folder = paste0("/Data/",product,"_",DDates[i],sep="")
      dir.create(file.path(dirname(paste0(outputfolder)), folder))
      
      HDF_list = list.files(path = outputfolder, pattern = paste0(product,".A",substr(DDates[i],1,4), 
                                             str_pad(yday(as.Date(DDates[i],format="%Y-%m-%d")),3,"left",pad="0"),
                                             ".*",sep=""), recursive = T)
      
      file.copy(from=paste0(outputfolder,"/",HDF_list), 
                  to=paste0(file.path(dirname(outputfolder), folder),"/",HDF_list))
      

      gc()
    }
  }

  HDF_wrong = list.files(path = paste0(outputfolder,"/"), pattern = "*.hdf", recursive = F, full.names = T)
  file.remove(HDF_wrong)
  

}




MODIS_IST_down = function(start, end, path ,username, password, aoi) {
  outputfolder = paste0(path, "/Data", sep="")
  python_path = paste0(path, "/Python_code", sep="")

  products_IST= c("MOD29P1D","MOD29P1N","MYD29P1D","MYD29P1N")
  
  DDates <- seq(as.Date(start,format="%Y-%m-%d"), as.Date(end,format="%Y-%m-%d"), by=1)
  
  for (i in 1:length(DDates)){
    
    for (l in 1:length(products_IST)){
      product_IST=products_IST[l]
      # Download files 
      start_time =paste0(DDates[i], "T00:00:00Z", sep="")
      end_time=paste0(DDates[i], "T23:59:00Z", sep="")
      
      folder = paste0("/Data/",product_IST,"_",DDates[i],sep="")
      dir.create(file.path(dirname(paste0(outputfolder)), folder))
                         
      source_python(paste0(python_path,"/MODIS_Download_IST_fun.py") )
      download_MODIS_function(product_IST, start_time, end_time, aoi,username, password)
      xml_files=list.files(pattern="*.xml")
      file.remove(xml_files)
      
      downloade_path =  dirname(rstudioapi::getSourceEditorContext()$path)

      
      HDF_list = list.files(path = downloade_path, pattern = paste0(product_IST,".A",substr(DDates[i],1,4), 
                                                                  str_pad(yday(as.Date(DDates[i],format="%Y-%m-%d")),3,"left",pad="0"),
                                                                  ".*",sep=""), recursive = T)


      
      file.copy(from=paste0(downloade_path,"/",HDF_list), 
                  to=paste0(dirname(outputfolder), folder,"/",HDF_list))
        
      

      
      gc()
    }
    
    
    
  }
  HDF_wrong = list.files(path = downloade_path, pattern = "*.hdf", recursive = F)
  file.remove(HDF_wrong)

}





Merge_LST= function(start, end, path) {
  products <- c("MOD11A1","MYD11A1")
  
  type = c("day", "night")
  
  Dates = as.Date(start,format="%Y-%m-%d")
  end = as.Date(end,format="%Y-%m-%d")
  
  
  python_path = paste0(path, "/Python_code", sep="")
  data_path = paste0(path, "/Data", sep="")

  
  while (Dates <= end){
    theDate = format((Dates),"%d-%m-%Y")
    print(theDate)
    for (h in 1:length(products)){
      product=products[h]
      print(product)
      
      LST_dir = paste0(data_path, "/", products[h],"_",Dates, sep="")
      
      DOY = lubridate::yday(Dates)
      print(LST_dir )
      if (dir.exists(LST_dir)){
        
        setwd(LST_dir)
        
        HDF_files = list.files(LST_dir)
        
        source_python(paste0(python_path,"/conv_LST_day.py", sep=""))
        
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
          
          
          
          gc()
          
          # Night data 
          source_python(paste0(python_path,"/conv_LST_night.py",sep=""))
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
          
          
          
          
          #Deletes all other files 
          fold <- LST_dir
          
          # get all files in the directories, recursively
          f <- list.files(fold, pattern= "*m.tif", include.dirs = F, full.names = T, recursive = T)
          
          file.remove(f)
          
          
          
          # transform to CRS and move
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
                        to=paste0(data_path,"/LST/",name_out,sep=""))
            
          }
          
          gc()
          
        } else {
          print("Dir does not exists!")
        }
      }
      
    }
    gc()
    temp_files = list.files(temp_dir, full.names = T, recursive = T)
    file.remove(temp_files)
    
    LST_MOD = list.files(path = paste0(data_path,"/LST",sep=""), pattern = paste0("projMOD11A1", "_", theDate, ".*.tif", sep=""), full.names = T)
    LST_MYD = list.files(path = paste0(data_path,"/LST",sep=""), pattern = paste0("projMYD11A1", "_", theDate, ".*.tif", sep=""), full.names = T)
    LST_files = c(LST_MOD, LST_MYD)
    
    print(LST_files)
    
    r= list()
    
    ras_org=raster(paste0(data_path,'/Sample_data/AntAir_ICE_2003_001.tif'))
    
    for (k in 1:length(LST_files)){ 
      ras_imp=raster(LST_files[k])
      ras_imp=raster::reclassify(ras_imp, c(-1, 150, NA)) # Mask for values outside the temperature range 
      print(k)
      
      r= c(r,ras_imp)
    }
    # Calculate mean 
    mosaic_mean = do.call(mosaic, c(r, fun = mean, na.rm = T, tolerance=10))
    mosaic_mean = round(((mosaic_mean - 273.15 )), digits = 2) 
    
    mosaic_mean=raster::resample(mosaic_mean,ras_org, method ="bilinear")
    
    names(mosaic_mean) =  "Skin"
    
    load(paste0(path,"/models/lmModel.rda",sep=""))
    
    p <- predict(mosaic_mean, lmModel)
    
    # Write raster 
    name_end = paste0(data_path,"/LST/AntAir_", theDate,".tif", sep="")
    writeRaster(p, name_end, format="GTiff", options=c("COMPRESS=NONE"), overwrite=TRUE)
    
    
    
    # New Date
    Dates <- Dates + 1 
    
    
    gc()
    temp_files = list.files(temp_dir, full.names = T, recursive = T)
    file.remove(temp_files)
  }
  
  
  
  
  
  
  
  
  
  
}


Merge_IST = function(start, end, outputfolder,username, password, aoi) {
  
  DDates <- seq(as.Date(start,format="%Y-%m-%d"), as.Date(end,format="%Y-%m-%d"), by=1)
  
  data_path = paste0(path, "/Data", sep="")
  path_out = paste0(path, "/Data/IST", sep="")
  
  for(i in 1:length(DDates)){
    theDate = format((DDates[i]),"%d-%m-%Y")
    
    
    products_IST= c("MOD29P1D","MOD29P1N","MYD29P1D","MYD29P1N")
    
    for (h in 1:length(products_IST)){
      product=products_IST[h]
      
      source_python(paste0(path,"/Python_code/Conv_IST.py",sep=""))
      IST_dir = paste0(data_path, "/", product,"_",DDates[i],'/', sep="")
      
      setwd(IST_dir)
      
      HDF_files=list.files(IST_dir,pattern="*.hdf")
      
      if(length(HDF_files) == 0) {
        print("no_data")
        
      } else{
        # Converts to  tiff
        for (ii in 1:length(HDF_files)){
          conv_MODIS(HDF_files[ii])
          
        }
        # Merge
        all_my_rasts = list.files(IST_dir,pattern="*.Ice_Surface_Temperature.tif")
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
        file.rename(from=paste0(IST_dir,name_out,sep=""), 
                    to=paste0(data_path,"/IST/",name_out,sep=""))
        
        fold <- IST_dir
        f <- list.files(fold, pattern= "*.tif", include.dirs = F, full.names = T, recursive = T)
        file.remove(f)
        gc()
      }
      
      
    }
    
    
    #date = format((Dates[x]),"%d-%m-%Y")
    
    IST_MOD = list.files(path = paste0(data_path,'/IST'), pattern = paste0("projMOD29P1", ".*_", theDate, ".tif", sep=""), full.names = T)
    IST_MYD = list.files(path = paste0(data_path,'/IST'), pattern = paste0("projMYD29P1", ".*_", theDate, ".tif", sep=""), full.names = T)
    
    
    IST_files = c(IST_MOD, IST_MYD)
    
    print(IST_files)
    
    r= list()
    ras_org= raster(paste0(data_path,'/Sample_data/AntAir_ICE_2003_001.tif'))
    
    
    for (k in 1:length(IST_files)){ 
      ras_imp=raster(IST_files[k])
      ras_imp=raster::reclassify(ras_imp, c(-1, 210, NA)) # Mask for values outside the temperature range 
      ras_imp=raster::reclassify(ras_imp, c(273, 350, NA)) # Mask for values outside the temperature range 
      
      
      r= c(r,ras_imp)
    }
    
    print(r)
    
    # Calculate mean 
    mosaic_mean = do.call(mosaic, c(r, fun = mean, na.rm = T, tolerance=10))
    mosaic_mean = round(((mosaic_mean - 273.15 )), digits = 2) 
    
    mosaic_mean=raster::resample(mosaic_mean,ras_org, method ="bilinear")
    
    names(mosaic_mean) =  "Skin"
    
    load(paste0(path,"/models/lmModel_IST.rda",sep=""))
    
    p <- predict(mosaic_mean, lmModel_IST)
    
    # Write raster 
    name_end = paste0(data_path,"/IST/AntAir_",theDate,"_IST.tif", sep="")
    writeRaster(p, name_end, format="GTiff", options=c("COMPRESS=NONE"), overwrite=TRUE)  
    
    
    
    
    gc()
    temp_files = list.files(temp_dir, full.names = T, recursive = T)
    file.remove(temp_files)
  }
}
  

  

AntAir_ICE_finalisation = function(start, end, folder) {
  data_path = paste0(path, "/Data", sep="")
  path_out = paste0(path, "/AntAir_ICE", sep="")
  
  Dates <- seq(as.Date(start,format="%Y-%m-%d"), as.Date(end,format="%Y-%m-%d"), by=1)
  
  
  for(x in 1:length(Dates)){
    date = format((Dates[x]),"%d-%m-%Y")

    LST = rast(paste0(data_path,"/LST/AntAir_",date,".tif"))

    IST = rast(paste0(data_path,"/IST/AntAir_",date,"_IST.tif"))
    LST_large = extend(LST,IST,snap="in")
    
    AntAir_Temp = raster::merge(raster(LST_large),raster(IST))
    AntAir_Temp = round(AntAir_Temp*10, digits =0)


    AntAir= AntAir_Temp
    AntAir@data@names = "AirTemperature"
    
    
    DOY = yday(as.Date(date, format="%d-%m-%Y"))
    Year = substr(date,7,11)
    
    name_end = paste0(path_out,"/AntAir_ICE_",Year,"_",str_pad(DOY,width=3,side="left", pad = "0"),".tif")
    writeRaster(AntAir, name_end, datatyper = "INT1S", gdal=c("COMPRESS=LZW"), overwrite=TRUE)  

  }
  
}






