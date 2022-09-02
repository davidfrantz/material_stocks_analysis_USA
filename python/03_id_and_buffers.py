#!/usr/bin/python3
import os
import sys
import ogr
from gdal import osr, ogr
import pandas as pd

##### buffers road and rail data based on a given id and a given feature width
##### _______________________________________
    
inputPath = str(sys.argv[1]).split(" ")[0]  ## "/data/Jakku/osm_test/03_shapes/uganda/reprojected/uganda-railway.shp"
country = str(sys.argv[2]).split(" ")[0]  ## country to be computed 
type = str(sys.argv[3]).split(" ")[0]  ## "rail" or "road" 
bufferDir = str(sys.argv[4]).split(" ")[0]  ## output directory for buffered vectors

def main():
    counter = 0
    
    if(type == "rail"):
        field = "railway"
    elif(type == "road"):
        field = "category"
        
	## Modify: Lines 40 to 50
    
    extension = os.path.splitext(inputPath)[1]
    if(extension == ".shp"):
        driver = ogr.GetDriverByName("ESRI Shapefile")
    elif(extension == ".sqlite"):
        driver = ogr.GetDriverByName("SQLite")
        
    #fd = ogr.FieldDefn("bwidth", ogr.OFTReal)
    #dataSource = driver.Open(inputPath,1)
		
    fd = ogr.FieldDefn("bwidth", ogr.OFTReal)
    fd2 = ogr.FieldDefn("layer", ogr.OFTInteger)
    fd3 = ogr.FieldDefn("brdtun", ogr.OFTInteger)
    dataSource = driver.Open(inputPath,1)

    layer = dataSource.GetLayer()

    layer.CreateField(fd)
    layer.CreateField(fd2)
    layer.CreateField(fd3)
    inLayerDefn = layer.GetLayerDefn()
    featureCount = layer.GetFeatureCount()

    #using spatial reference from jpn_equi.shp to create buffer
    
    dataset = driver.Open(inputPath)
    layer2 = dataset.GetLayer()
    sref = layer2.GetSpatialRef()   

    if not os.path.exists(bufferDir + "/" + country):
        os.makedirs(bufferDir + "/" + country)
    
    base=os.path.basename(inputPath)
    fn = os.path.splitext(base)[0]
    
    if(extension == ".shp"):
       bufferedFilePath = bufferDir + "/" + country + "/" + fn + ".shp"
    elif(extension == ".sqlite"):
       bufferedFilePath = bufferDir + "/" + country + "/" + fn + ".sqlite"
    	
    bufferedFile = driver.CreateDataSource(bufferedFilePath)
    bufferedLayer = bufferedFile.CreateLayer(bufferedFilePath, sref, geom_type = ogr.wkbPolygon)
    bufferedFeaturedfn = bufferedLayer.GetLayerDefn() 
    
    for i in range(0, inLayerDefn.GetFieldCount()):
        fieldDefn = inLayerDefn.GetFieldDefn(i)
        bufferedLayer.CreateField(fieldDefn)

    if (field == "category"):
        for feature in layer:
            counter = counter + 1
            print(str(counter) + " / " + str(featureCount))
        
                        # bridges and tunnels
            if(feature.GetField("bridge") != None and feature.GetField("category") == "motorway"):
                feature.SetField("brdtun",3)
            elif(feature.GetField("bridge") != None and feature.GetField("category") == "motorway_link"):
                feature.SetField("brdtun",3)
            elif (feature.GetField("bridge") != None):
                feature.SetField("brdtun", 1)
            elif (feature.GetField("tunnel") == "yes"):
                feature.SetField("brdtun", 2)
            else:
                feature.SetField("brdtun",4)

            # for highways
            if (feature.GetField(field) == "bridleway"):
                feature.SetField("layer", 24)
            elif (feature.GetField(field) == "construction"):
                feature.SetField("layer", 27)
            elif(feature.GetField(field) == "cycleway"):
                feature.SetField("layer",23)
            elif(feature.GetField(field) == "footway"):
                feature.SetField("layer",22)
            elif(feature.GetField(field) == "living_street"):
                feature.SetField("layer",13)
            elif(feature.GetField(field) == "motorway" and feature.GetField("bridge") != None):
                feature.SetField("layer",33)
            elif(feature.GetField(field) == "motorway" and feature.GetField("bridge") == None):
                feature.SetField("layer",1)
            elif(feature.GetField(field) == "motorway_link" and feature.GetField("bridge") != None):
                feature.SetField("layer",34)
            elif(feature.GetField(field) == "motorway_link" and feature.GetField("bridge") == None):
                feature.SetField("layer",2)
            elif (feature.GetField(field) == "path"):
                feature.SetField("layer", 21)
            elif(feature.GetField(field) == "pedestrian"):
                feature.SetField("layer",26)
            elif (feature.GetField(field) == "platform"):
                feature.SetField("layer", 32)
            elif(feature.GetField(field) == "primary"):
                feature.SetField("layer",3)
            elif(feature.GetField(field) == "primary_link"):
                feature.SetField("layer",4)
            elif (feature.GetField(field) == "raceway"):
                feature.SetField("layer", 28)
            elif(feature.GetField(field) == "residential"):
                feature.SetField("layer",12)
            elif(feature.GetField(field) == "rest_area"):
                feature.SetField("layer",29)
            elif (feature.GetField(field) == "road"):
                feature.SetField("layer", 30)
            elif(feature.GetField(field) == "secondary"):
                feature.SetField("layer",7)
            elif(feature.GetField(field) == "secondary_link"):
                feature.SetField("layer",8)
            elif(feature.GetField(field) == "service"):
                feature.SetField("layer",14)
            elif(feature.GetField(field) == "services"):
                feature.SetField("layer",31)
            elif(feature.GetField(field) == "steps"):
                feature.SetField("layer",25)
            elif(feature.GetField(field) == "tertiary"):
                feature.SetField("layer",9)
            elif(feature.GetField(field) == "tertiary_link"):
                feature.SetField("layer",10)
            elif (feature.GetField(field) == "track_1"):
                feature.SetField("layer",15)
            elif (feature.GetField(field) == "track_2"):
                feature.SetField("layer",16)
            elif (feature.GetField(field) == "track_3"):
                feature.SetField("layer",17)
            elif (feature.GetField(field) == "track_4"):
                feature.SetField("layer",18)
            elif (feature.GetField(field) == "track_5"):
                feature.SetField("layer",19)
            elif (feature.GetField(field) == "track_na"):
                feature.SetField("layer",20)
            elif(feature.GetField(field) == "trunk"):
                feature.SetField("layer",5)
            elif(feature.GetField(field) == "trunk_link"):
                feature.SetField("layer",6)
            elif (feature.GetField(field) == "unclassified"):
                feature.SetField("layer", 11)
            else:
                 feature.SetField("layer", 99)
            
            if(feature.GetField("bridge") != None and feature.GetField(field) != "motorway" and feature.GetField(field) != "motorway_link"):
                feature.SetField("layer",35)
            
            if (feature.GetField(field) == None):
               layer.DeleteFeature(feature.GetFID())
               continue
            if (feature.GetField("layer") > 35):
               layer.DeleteFeature(feature.GetFID())
               continue
               
            layer.SetFeature(feature)
               
               ### buffer widths
            if (feature.GetField(field) == "motorway"):
                bfwidth = 13.6
            elif (feature.GetField(field) == "motorway_link"):
                bfwidth = 6.5
            elif (feature.GetField(field) == "primary"):
                bfwidth = 6.0
            elif (feature.GetField(field) == "primary_link"):
                bfwidth = 5.5
            elif (feature.GetField(field) == "trunk"):
                bfwidth = 9.6
            elif (feature.GetField(field) == "trunk_link"):
                bfwidth = 6.5
            elif (feature.GetField(field) == "secondary"):
                bfwidth = 5.3
            elif (feature.GetField(field) == "secondary_link"):
                bfwidth = 5.1
            elif (feature.GetField(field) == "tertiary"):
                bfwidth = 4.9
            elif (feature.GetField(field) == "tertiary_link"):
                bfwidth = 4.5
            elif (feature.GetField(field) == "unclassified"):
                bfwidth = 4.5
            elif (feature.GetField(field) == "residential"):
                bfwidth = 4.5
            elif (feature.GetField(field) == "living_street"):
                bfwidth = 4.5
            elif (feature.GetField(field) == "service"):
                bfwidth = 2.5
            elif (feature.GetField(field) == "track_1"):
                bfwidth = 2.5
            elif (feature.GetField(field) == "track_2"):
                bfwidth = 2.5
            elif (feature.GetField(field) == "track_3"):
                bfwidth = 2
            elif (feature.GetField(field) == "track_4"):
                bfwidth = 2
            elif (feature.GetField(field) == "track_5"):
                bfwidth = 2
            elif (feature.GetField(field) == "track_na"):
                bfwidth = 2
            elif (feature.GetField(field) == "path"):
                bfwidth = 1
            elif (feature.GetField(field) == "footway"):
                bfwidth = 1.8
            elif (feature.GetField(field) == "cycleway"):
                bfwidth = 1.5
            elif (feature.GetField(field) == "bridleway"):
                bfwidth = 1.5
            elif (feature.GetField(field) == "steps"):
                bfwidth = 1.5
            elif (feature.GetField(field) == "pedestrian"):
                bfwidth = 4
            elif (feature.GetField(field) == "construction"):
                bfwidth = 3
            elif (feature.GetField(field) == "raceway"):
                bfwidth = 3.6
            elif (feature.GetField(field) == "rest_area"):
                bfwidth = 6
            elif (feature.GetField(field) == "road"):
                bfwidth = 4
            elif (feature.GetField(field) == "services"):
                bfwidth = 6
            elif (feature.GetField(field) == "platform"):
                bfwidth = 1.8
            elif (feature.GetField(field) == "motorway on brid"):
                bfwidth = 13.6
            elif (feature.GetField(field) == "motorway_link on bridge"):
                bfwidth = 6.5
            else:
                bfwidth = 99999
                continue   
            if (feature.GetField(field) == None):
                layer.DeleteFeature(feature.GetFID())
                
            if (bfwidth > 100):
                layer.DeleteFeature(feature.GetFID())
                
            feature.SetField("bwidth",bfwidth)
            layer.SetFeature(feature)
            
            # This creates a buffer feature
            if (feature.GetField("layer") < 36 and bfwidth < 100):
                featureGeom = feature.GetGeometryRef()
                bufferGeom = featureGeom.Buffer(bfwidth)
                outFeature = ogr.Feature(bufferedFeaturedfn)
                outFeature.SetGeometry(bufferGeom)
                for i in range(0, bufferedFeaturedfn.GetFieldCount()):
                    outFeature.SetField(bufferedFeaturedfn.GetFieldDefn(i).GetNameRef(), feature.GetField(i))
                bufferedLayer.CreateFeature(outFeature)
                outFeature = None
            
    if (field == "railway"):
        for feature in layer:
            counter = counter + 1
            print(str(counter) + " / " + str(featureCount))
            
            # # bridges and tunnels
            if (feature.GetField("bridge") != None):
                feature.SetField("brdtun", 1)
            elif (feature.GetField("tunnel") == "yes"):
                feature.SetField("brdtun", 2)
            else:
                feature.SetField("brdtun",3)
                
            if(feature.GetField(field) == "abandoned"):
               feature.SetField("layer",2)
            elif(feature.GetField(field) == "construction"):
               feature.SetField("layer",10)
            elif(feature.GetField(field) == "disused"):
               feature.SetField("layer",3)
            elif(feature.GetField(field) == "funicular"):
               feature.SetField("layer",13)
            elif(feature.GetField(field) == "light_rail"):
               feature.SetField("layer",5)
            elif(feature.GetField(field) == "miniature"):
               feature.SetField("layer", 15)
            elif(feature.GetField(field) == "monorail"):
               feature.SetField("layer",14)
            elif(feature.GetField(field) == "narrow_gauge"):
                feature.SetField("layer",7)
            elif(feature.GetField(field) == "preserved"):
               feature.SetField("layer",8)
            elif(feature.GetField(field) == "rail"):
                feature.SetField("layer",1)
            elif(feature.GetField(field) == "subway" and feature.GetField("tunnel") == "yes"):
                feature.SetField("layer",6)
            elif(feature.GetField(field) == "subway" and feature.GetField("tunnel") == "no" and feature.GetField("bridge") == "yes"):
               feature.SetField("layer",11)
            elif(feature.GetField(field) == "subway" and feature.GetField("tunnel") == "no" and feature.GetField("bridge") == "viaduct"):
               feature.SetField("layer",11)
            elif(feature.GetField(field) == "subway" and feature.GetField("tunnel") == None and feature.GetField("bridge") == "yes"):
               feature.SetField("layer",11)
            elif(feature.GetField(field) == "subway" and feature.GetField("tunnel") == None and feature.GetField("bridge") == "viaduct"):
               feature.SetField("layer",11)
            elif(feature.GetField(field) == "subway" and feature.GetField("tunnel") == None and feature.GetField("bridge") == None):
               feature.SetField("layer",12)
            elif(feature.GetField(field) == "tram"):
                feature.SetField("layer",4)
            elif(feature.GetField(field) == "platform"):
                feature.SetField("layer",9)
            else:
                feature.SetField("layer", 99)
           
            if (feature.GetField(field) == None):
               layer.DeleteFeature(feature.GetFID())
               continue
            if (feature.GetField("layer") > 15):
               layer.DeleteFeature(feature.GetFID())
               continue
			   
            layer.SetFeature(feature)
       
            ### buffer widths
            if (feature.GetField(field) == "rail"):
                bfwidth = 6
            elif (feature.GetField(field) == "abandoned"):
                bfwidth = 2
            elif (feature.GetField(field) == "disused"):
                bfwidth = 2
            elif (feature.GetField(field) == "tram"):
                bfwidth = 3.5
            elif (feature.GetField(field) == "light_rail"):
                bfwidth = 3.5
            elif (feature.GetField(field) == "subway"):
                bfwidth = 5
            elif (feature.GetField(field) == "narrow_gauge"):
                bfwidth = 3.5
            elif (feature.GetField(field) == "preserved"):
                bfwidth = 3.5
            elif (feature.GetField(field) == "platform"):
                bfwidth = 2
            elif (feature.GetField(field) == "construction"):
                bfwidth = 8.5
            elif (feature.GetField(field) == "miniature"):
                bfwidth = 2
            elif (feature.GetField(field) == "monorail"):
                bfwidth = 3.5
            elif (feature.GetField(field) == "funicular"):
                bfwidth = 3.5
            else:
                bfwidth = 99999
                continue
                   
            if (feature.GetField(field) == None):
                layer.DeleteFeature(feature.GetFID())
            if (bfwidth > 100):
                layer.DeleteFeature(feature.GetFID())

            feature.SetField("bwidth",bfwidth)
            layer.SetFeature(feature)

            # This creates a buffer feature
            featureGeom = feature.GetGeometryRef()
            bufferGeom = featureGeom.Buffer(bfwidth)
            outFeature = ogr.Feature(bufferedFeaturedfn)
            outFeature.SetGeometry(bufferGeom)
            for i in range(0, bufferedFeaturedfn.GetFieldCount()):
                outFeature.SetField(bufferedFeaturedfn.GetFieldDefn(i).GetNameRef(), feature.GetField(i))
            bufferedLayer.CreateFeature(outFeature)
            outFeature = None

    dataSource.Destroy()
    dataSource = None
    bufferedFile.Destroy()
    bufferedFile = None

        
if __name__ == '__main__':
    main()