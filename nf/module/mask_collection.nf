
// rasterized federal states (binary [0/1])
process import_mask {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(mask)

    output:
    tuple val(tile), val(state), file('*.tif')

    """
    # COPY MASK and set zero = nodata
    cp $mask import_mask.tif
    gdal_edit.py -a_nodata 0 import_mask.tif
    """

}


// make sure that bakckground value is 0 (not nodata)
// assuming initial nodata value is 255
process mask_collection_byte {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(mask), file(input)
//    val(tag)

    output:
    tuple val(tile), val(state), file('import_*.tif')

    """
    base=\$(basename $input)
    cp $input tmp.tif
    gdal_edit.py -a_nodata 199 tmp.tif # some illogical value
    gdal_calc.py \
        -A tmp.tif --allBands=A \
        -Z $mask \
        --calc='(A*(A!=255)*Z)' \
        --outfile=import_\$base \
        $params.gdal.calc_opt_byte
    """

}


// make sure that bakckground value is 0 (not nodata)
// assuming initial nodata value is < 0
process mask_collection_int16 {

    label 'gdal'
    
    input:
    tuple val(tile), val(state), file(mask), file(input)
//    val(tag)

    output:
    tuple val(tile), val(state), file('import_*.tif')

    """
    base=\$(basename $input)
    cp $input tmp.tif
    gdal_edit.py -a_nodata 32767 tmp.tif # some illogical value
    gdal_calc.py \
        -A tmp.tif --allBands=A \
        -Z $mask \
        --calc='(A*(A>0)*Z)' \
        --outfile=import_\$base \
        $params.gdal.calc_opt_int16
    """

}

