// building volume

process volume {

    label 'gdal'
    label 'mem_2'

    input:
    tuple val(tile), val(state), file(area), file(height)

    output:
    tuple val(tile), val(state), file('volume_*.tif')

    publishDir "$params.dir.pub/$state/$tile/volume/building", mode: 'copy'

    """
    base=$area
    base=\$(basename \$base)
    base=\${base/area/volume}
    gdal_calc.py \
        -A $area \
        -H $height \
        --calc="( A * H )" \
        --outfile=\$base \
        $params.gdal.calc_opt_float
    """

}

