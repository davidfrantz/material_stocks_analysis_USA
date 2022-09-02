#!/usr/bin/python

# Use: 04_rasterizeVector.py tile
# parallel -a tiles.txt --eta -j 10 python 04_rasterizeVector{}

##### rasterizes vector data
##### _______________________________________

import os
os.environ['OMP_NUM_THREADS'] = '1'

from osgeo import gdal
import sys
import time
from hubflow.core import *
from hubdc.core import *

print('Number of arguments:', len(sys.argv), 'arguments.')
print('Argument List:', str(sys.argv))

    
vectorDir = str(sys.argv[1]).split(" ")[0]  ## "/data/Jakku/temp_fs/osm_northeast/"
referenceGridDir = str(sys.argv[2]).split(" ")[0]  ## "/data/Jakku/usa/imperviousness/"
tile = str(sys.argv[3]).split(" ")[0]  ## X0069_Y0043
vectorBase = str(sys.argv[4]).split(" ")[0] ##"/us-northeast-highway.shp"
referenceGridBase = str(sys.argv[5]).split(" ")[0] ## "/NLCD_2016_Impervious_L48_20190405.tif"
country = str(sys.argv[6]).split(" ")[0]  ## country
ll = str(sys.argv[7]).split(" ")[0]  ##  can take "highway", "railway", "apron", "parking", "runway", "taxiway", "rail-brdtun", "road-brdtun"
outDir = str(sys.argv[8]).split(" ")[0]  ##  c"/data/Alderaan/osm_test/07_rasterized/"

s = time.time()
vectorPath = vectorDir + "/" + country + "/" + vectorBase
referenceGridPath = referenceGridDir + "/" + tile + "/" + referenceGridBase
print(referenceGridPath)
options = ['COMPRESS=LZW', 'BIGTIFF=YES', 'INTERLEAVE=BAND']

nm = ll
classes = 1
attribute = "layer"

if ll == "highway":
    classes = 35
    attribute = "layer"
if ll == "railway":
    classes = 15
    attribute = "layer"
if ll == "rail-brdtun":
    classes = 2
    attribute = "brdtun"
if ll == "road-brdtun":
    classes = 3
    attribute = "brdtun"
    
#drv = ogr.GetDriverByName('SQLite')
drv = ogr.GetDriverByName('ESRI Shapefile')
drv2 = ogr.GetDriverByName('ESRI Shapefile')

s = time.time()
print(outDir)
if(1==1):
#if not os.path.exists(outDir +"/" + country + "-" + ll + "/" + tile + "/"):
    if not os.path.exists(outDir + "/" + country + "-" + ll + "/vector/" + tile + "/"):
        os.makedirs(outDir + "/" + country + "-" + ll + "/vector/" + tile + "/")
        os.makedirs(outDir + "/temp/" + country + "-" + ll + "/vector/" + tile + "/")

    tempOutVectorPath = outDir + "/" + country + "-" + ll + "/vector/" + tile + "/fltemp.shp"
    print(tempOutVectorPath)
    controls = ApplierControls()
    #controls.setBlockFullSize()
    #controls.setBlockSize(1024)

    grid = Raster(referenceGridPath).grid()
    
    ### clip vector to reference raster extent
    referenceRaster = gdal.Open(referenceGridPath)
    ulx, xres, xskew, uly, yskew, yres = referenceRaster.GetGeoTransform()
    sizeX  = referenceRaster.RasterXSize * xres
    sizeY  = referenceRaster.RasterYSize * yres
    lrx = ulx + sizeX
    lry = uly + sizeY
	
    print([ulx, lry, lrx, uly])
    
    ds_in = gdal.OpenEx(vectorPath)
    ds_out = gdal.VectorTranslate(tempOutVectorPath, ds_in, format = 'ESRI Shapefile', spatFilter = [ulx, lry, lrx, uly])
   
    #d = drv.Open(tempOutVectorPath)

    #l = d.GetLayer()
    #spatialRef = l.GetSpatialRef()
    del ds_out

    dataSet = drv.Open(tempOutVectorPath, 1)
    layer = dataSet.GetLayer()
    featureCount = layer.GetFeatureCount()
    print(featureCount)
	    
    if(ll not in ["highway", "railway", "rail-brdtun", "road-brdtun"]):
        fd = ogr.FieldDefn("layer", ogr.OFTInteger)
        layer.CreateField(fd)
        counter = 0
        for feature in layer:
            counter = counter + 1
            print(str(counter) + " / " + str(featureCount))
            feature.SetField("layer", 1)
            layer.SetFeature(feature)
			    
    del layer, dataSet
    print("vector clipped" + "--- %s seconds ---" % (time.time() - s))

    raster = Raster(referenceGridPath)
    rds = raster.dataset()

    if(featureCount == 0):
        print("ft count zero")
        arr = np.zeros((classes, rds.xsize(), rds.ysize()))
        arr = arr.astype(np.uint8)
        rd = RasterDataset.fromArray(arr, grid=grid, driver=RasterDriver('GTiff'),
                                     filename = outDir + "/" + country + "-" + ll + "/" + tile + "/" + nm + ".tif", options=options)
        rd.setNoDataValue(value=255)
        rd = None

    if(featureCount != 0):
        print(attribute)
        classification = VectorClassification(tempOutVectorPath, attribute, minOverallCoverage=0, minDominantCoverage=0, oversampling=10)
        print(classification)
        print("Classification loaded")
        fraction = Fraction.fromClassification(outDir + "/temp/" + country + "-" + ll + "/" + tile + "/" + nm + ".tif", classification, grid=grid, controls=controls)
        print("Fraction created")
        fraction = fraction.array()
        print(np.amax(fraction))
        fraction[fraction < 0] = 0
        if(len(fraction) < classes):
            arr = np.zeros((classes-len(fraction), rds.xsize(), rds.ysize()))
            fraction = np.concatenate((fraction, arr), axis = 0)
        fraction = (fraction * 100).astype(np.uint8)
        if ll == "rail-brdtun":
            fraction = fraction[:-1]
        if ll == "road-brdtun":
            fraction = fraction[:-1]
        print("Fraction processed")

        rd = RasterDataset.fromArray(fraction, grid=grid, driver=RasterDriver('GTiff'), filename= outDir + "/" + country + "-" + ll + "/" + tile + "/" + nm + ".tif", options=options)
        rd.setNoDataValue(value=255)
        rd = None
    
    dataSet = None
    outds = None
    print("done" + "--- %s seconds ---" % (time.time() - s))
else:
    print("files exist")