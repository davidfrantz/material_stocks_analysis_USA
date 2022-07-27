
// area correction
process area_correction {

    label 'gdal'
    label 'mem_2'

    input:
    tuple val(tile), val(state), file(area), val(id), file(corr)

    output:
    tuple val(tile), val(state), file('*acor.tif'), val(id)

    """
    base=$area
    base=\$(basename \$base)
    base=\${base%%.tif}
    gdal_calc.py \
        -A $area --allBands=A \
        -B $corr \
        --calc="( A * (single(B)/10000) )" \
        --outfile=\$base"_acor.tif" \
        $params.gdal.calc_opt_byte
    """

}

