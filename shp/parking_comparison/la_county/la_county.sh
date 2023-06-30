#!/bin/bash

# perctentage of our parking area estimate in incorporated LA county


dforce force-cube -a MASK la_county.gpkg

for d in X*; do 

  echo $d; 

  cp /data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/US_CA/$d/area/other/area_other_parking* $d/
  cp /data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/US_CA/$d/area/other/area_other_rem* $d/
  cp /data/ahsoka/gi-sds/hub/mat_stocks/areacorr/USA/$d/true_area.tif $d/

  gdal_calc.py -A $d/area_other_parking.tif -B $d/area_other_remaining_impervious.tif -X $d/la_county.tif --calc='(A+B)*X' --outfile $d/intersect.tif  --creation-option='INTERLEAVE=BAND'  --creation-option='COMPRESS=LZW'  --creation-option='PREDICTOR=2'  --creation-option='BIGTIFF=YES'

  gdal_calc.py -A $d/true_area.tif -X $d/la_county.tif --calc='A*X/100'  --outfile $d/la_county_area.tif  --creation-option='INTERLEAVE=BAND'  --creation-option='COMPRESS=LZW'  --creation-option='PREDICTOR=2'  --creation-option='BIGTIFF=YES'

done

dforce force-mosaic .

imgsum mosaic/intersect.vrt 255
imgsum mosaic/la_county_area.vrt 255

# parking area in incorporated cities =  513652262.000000
# area of incorporated cities         = 3796040486.000000
#--------------------------------------------------------
# percentage = 13.53%

