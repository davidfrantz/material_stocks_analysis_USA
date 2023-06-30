#!/bin/bash

# perctentage of our parking area estimate in incorporated LA county

dforce force-cube phx-blkgrp-geom.shp -b phoenix

for d in X*; do 

  echo $d; 

  cp /data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/US_AZ/$d/area/other/area_other_parking* $d/
  cp /data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/US_AZ/$d/area/other/area_other_rem* $d/
  cp /data/ahsoka/gi-sds/hub/mat_stocks/areacorr/USA/$d/true_area.tif $d/

  gdal_calc.py -A $d/area_other_parking.tif -B $d/area_other_remaining_impervious.tif -X $d/phoenix.tif --calc='(A+B)*X' --outfile $d/intersect.tif  --creation-option='INTERLEAVE=BAND'  --creation-option='COMPRESS=LZW'  --creation-option='PREDICTOR=2'  --creation-option='BIGTIFF=YES'

  gdal_calc.py -A $d/true_area.tif -X $d/phoenix.tif --calc='A*X/100'  --outfile $d/phoenix_area.tif  --creation-option='INTERLEAVE=BAND'  --creation-option='COMPRESS=LZW'  --creation-option='PREDICTOR=2'  --creation-option='BIGTIFF=YES'

done

dforce force-mosaic .

imgsum mosaic/intersect.vrt 255
imgsum mosaic/phoenix_area.vrt 255

# parking area  =  321881557.000000
# area          = 3117411458.000000
#--------------------------------------------------------
# percentage = 10.33%

