// material stock

process mass {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(input), val(type), val(material), val(mi), val(pubdir)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass*.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    base=$input
    base=\$(basename \$base)
    base=\${base/area/mass}
    base=\${base/volume/mass}
    base=\${base%%.tif}
    gdal_calc.py \
        -A $input \
        --calc="( A * $mi )" \
        --outfile=\$base"_"$material".tif" \
        $params.gdal.calc_opt_float
    """

}


process mass_climate5 {

    label 'gdal'
    label 'mem_2'

    input:
    tuple val(tile), val(state), file(input), file(climate), 
        val(type), val(material), 
        val(mi1), val(mi2), val(mi3), val(mi4), val(mi5), val(pubdir)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass*.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    base=$input
    base=\$(basename \$base)
    base=\${base/area/mass}
    base=\${base/volume/mass}
    base=\${base%%.tif}
    gdal_calc.py \
        -A $input \
        -B $climate \
        --calc="( \
            ( A * (B == 1) * $mi1 ) + \
            ( A * (B == 2) * $mi2 ) + \
            ( A * (B == 3) * $mi3 ) + \
            ( A * (B == 4) * $mi4 ) + \
            ( A * (B == 5) * $mi5 ) )" \
        --outfile=\$base"_"$material".tif" \
        $params.gdal.calc_opt_float
    """

}


process mass_climate6 {

    label 'gdal'
    label 'mem_2'

    input:
    tuple val(tile), val(state), file(input), file(climate), 
        val(type), val(material), 
        val(mi1), val(mi2), val(mi3), val(mi4), val(mi5), val(mi6), val(pubdir)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass*.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    base=$input
    base=\$(basename \$base)
    base=\${base/area/mass}
    base=\${base/volume/mass}
    base=\${base%%.tif}
    gdal_calc.py \
        -A $input \
        -B $climate \
        --calc="( \
            ( A * (B == 1) * $mi1 ) + \
            ( A * (B == 2) * $mi2 ) + \
            ( A * (B == 3) * $mi3 ) + \
            ( A * (B == 4) * $mi4 ) + \
            ( A * (B == 5) * $mi5 ) + \
            ( A * (B == 6) * $mi6 ) )" \
        --outfile=\$base"_"$material".tif" \
        $params.gdal.calc_opt_float
    """

}

