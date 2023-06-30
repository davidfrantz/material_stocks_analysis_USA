#!/usr/bin/env python3

import sys
#import uuid
from osgeo import gdal
import pandas as pd
import numpy as np
import csv

#print('Number of arguments:', len(sys.argv), 'arguments.')
#print('Argument List:', str(sys.argv))

outPath = str(sys.argv[1]).split(" ")[0]
targetPath = str(sys.argv[2]).split(" ")[0]
zonesPath = str(sys.argv[3]).split(" ")[0]

targetDS = gdal.Open(targetPath)
zonesDS = gdal.Open(zonesPath)

targetND = targetDS.GetRasterBand(1).GetNoDataValue()
#zonesND = zonesDS.GetRasterBand(1).GetNoDataValue()

target = targetDS.ReadAsArray()

#gt = targetDS.GetGeoTransform()
#randomPath = "/vsimem/" + str(uuid.uuid4()) + ".vrt"
#zonesDS_T = gdal.Translate(randomPath, zonesDS, xRes = gt[1], yRes = -gt[5], resampleAlg = "mode")
#zones = zonesDS_T.ReadAsArray()

#zonesDS_T = None
#gdal.Unlink(randomPath)

zones = zonesDS.ReadAsArray()

## ID unique ids in zones, write to array
uids = np.unique(zones)
sums = []

## loop through ids, for each id, build sum of target[zones == ID)
try:
    for uid in uids:
        sums.append(np.sum(target, where = (zones == uid) & (target != targetND)))

        all = [uids, sums]

    DF = pd.DataFrame(np.transpose(all), columns = ['zone','sum'])
    DF.to_csv(outPath, sep=";", header=True, index=False, quoting = csv.QUOTE_NONE)

except ValueError:
    print("WARNING: outPath " + outPath + " not created. Target dataset and zones must be of same shape.") 
