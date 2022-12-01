def conv_MODIS(file):

	import os, sys
	import numpy as N

	# Use pyhdf library - see http://hdfeos.org/software/pyhdf.php
	from pyhdf.SD import SD, SDC

	#import osgeo.gdal as gdal
	#import osgeo.osr as osr
	
	try:
	    from osgeo import gdal
	except ImportError:
	    import gdal
	
	try:
	    from osgeo import osr
	except ImportError:
	    import osr



	# Target dataset
	dataset_name = 'LST_Day_1km'

	# Open HDF file
	hdffn = file
	#print(hdffn)
	hdf = SD(hdffn, SDC.READ)

	# List available SDS datasets.
	# print hdf.datasets()

	# Get dataset attributes from StructMetadata text attribute
	metadata = hdf.attributes()
	struct_metadata = metadata['StructMetadata.0'].split('\n')
	lineno = 0
	for txtline in struct_metadata:
	    if txtline.find('=') > -1:
	        valtxt = txtline.split('=')[1]
	    if txtline.find('XDim=') > -1:
	        xdim = int(valtxt)
	    elif txtline.find('YDim=') > -1:
	        ydim = int(valtxt)
	    elif txtline.find('UpperLeftPointMtrs=') > -1:
	        ulx,uly = map(float, (valtxt.strip('()')).split(',') )
	    elif txtline.find('LowerRightMtrs=') > -1:
	        lrx,lry = map(float, (valtxt.strip('()')).split(',') )
	    elif txtline.find('Projection=') > -1:
	        projection = valtxt
	    elif txtline.find('ProjParams=') > -1:
	        projparams = map(float, (valtxt.strip('()')).split(','))
	    elif txtline.find('SphereCode=') > -1:
	        sphere = int(valtxt)
	    elif txtline.find('GridOrigin=') > -1:
	        origin = valtxt
	    elif txtline.find( ("DataFieldName=\"%s\"" % dataset_name) ) > -1:
	        # This condition breaks us out of reviewing the metadata with the latest relevant values
	        break
	    lineno = lineno + 1
	# Extract values from projparams
	new_projparams=list(projparams)
	sphere_radius = new_projparams[0]
	proj_latitude_origin = new_projparams[5] / 1000000.0
	
	# Set the grid resolution
	resx = (lrx-ulx) / xdim
	resy = (uly-lry) / ydim
	# Set proj4 string for projection
	proj4str =("+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs")
	srs = osr.SpatialReference()
	srs.ImportFromProj4(proj4str)
	
	# Read Ice Surface Temperatures (IST) dataset:
	#   array data, scale and offset for values, data key
	ist = hdf.select(dataset_name)
	ist_array = N.array(ist[:,:],dtype=N.float32)
	ist_scale = ist.scale_factor
	#ist_offset = ist.add_offset
	#print ("IST scale  = %8.3f" % ist_scale)
	#print ("IST offset = % 8.3f" % ist_offset)
	# The key attribute contains information on the range of values to be expected
	# In this case, anything above 50 is considered to be a valid temperature
	#print ist.Key
	# Apply scale and offset to get IST in degrees Kelvin, and values at 50 below
	# representing certain flagged issues with data at that location
	ist_array = (ist_scale * ist_array) #+ ist_offset
	# Create an index to valid IST values
	idx = N.nonzero( ist_array > 50.0 )
	# Show some basic IST array information
	#print("IST array size:", ist_array.shape)
	#print() ("IST   minimum = %6.2f   maximum = %6.3f" % \
	#    (N.min(ist_array[idx]), N.max(ist_array[idx])))

	# Write array to GeoTIFF file
	# See https://pcjericks.github.io/py-gdalogr-cookbook/raster_layers.html#create-raster-from-array
	gtiffdrv = gdal.GetDriverByName('Gtiff')
	tiffn = ("%s.%s.tif" % (hdffn[:-4],dataset_name))
	outds = gtiffdrv.Create(tiffn, xdim, ydim, 1, gdal.GDT_Float32)
	outds.SetGeoTransform((ulx, resx, 0, uly, 0, -resy))
	outband = outds.GetRasterBand(1)
	outband.WriteArray(ist_array)
	outband.FlushCache()
	outds = None

