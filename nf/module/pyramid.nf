// image pyramids

process pyramid {

    label 'gdal'
    
    input:
    tuple file(input), val(pubdir)

    output:
    file('*.ovr')

    publishDir "$pubdir", mode: 'copy'

    """
    gdaladdo -ro --config COMPRESS_OVERVIEW DEFLATE --config BIGTIFF_OVERVIEW YES -r average $input 2 4 8 16 32
    """

}

