/** total stock
-----------------------------------------------------------------------**/

include { multijoin; remove }                          from './defs.nf'
include { finalize }                           from './finalize.nf'

workflow mass_grand_total {

    take:
    street; rail; other; building; zone


    main:
    mass_grand_total_t_10m2(
        multijoin(
           [street.map{ remove(it, 2) }, 
            rail.map{ remove(it, 2) }, 
            other.map{ remove(it, 2) }, 
            building.map{ remove(it, 2) }], [0,1,2]
        )
    ) \
    | mass_grand_total_t_10m2_nodata_remove \
    | mass_grand_total_kt_100m2 \
    | mass_grand_total_Mt_1km2 \
    | mass_grand_total_Gt_10km2


    // tile, state, category, dimension, material, basename, filename -> 1st channel of finalize
    all_published = 
        mass_grand_total_t_10m2.out
        .mix(   mass_grand_total_kt_100m2.out,
                mass_grand_total_Mt_1km2.out,
                mass_grand_total_Gt_10km2.out)
        .map{
            [ it[0], it[1], "", "", "", it[4].name, it[4] ] }

    finalize(all_published, zone)

}


process mass_grand_total_t_10m2 {

    label 'gdal'
    label 'mem_4'

    input:
    tuple val(tile), val(state), val(material), 
        file(street), file(rail), file(other), file(building)

    output:
    tuple val(tile), val(state), val("total"), val(material), file('mass_grand_total_t_10m2.tif')

    publishDir "$params.dir.pub/$state/$tile", mode: 'copy'

    """
    gdal_calc.py \
        -A $street \
        -B $other \
        -C $rail \
        -D $building \
        --calc="(A+B+C+D)" \
        --outfile=mass_grand_total_t_10m2.tif \
        $params.gdal.calc_opt_float
    """

}


process mass_grand_total_t_10m2_nodata_remove {

    label 'gdal'

    input:
    tuple val(tile), val(state), val(type), val(material), file(mass)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass_grand_total_t_10m2_nodata_remove.tif')

    """
    cp $mass temp.tif
    gdal_edit.py -a_nodata 32767 temp.tif
    gdal_calc.py \
        -A temp.tif \
        --calc="(A*(A>0))" \
        --outfile=mass_grand_total_t_10m2_nodata_remove.tif \
        $params.gdal.calc_opt_float
    """

}


process mass_grand_total_kt_100m2 {

    label 'gdal'

    input:
    tuple val(tile), val(state), val(type), val(material), file(mass)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass_grand_total_kt_100m2.tif')

    publishDir "$params.dir.pub/$state/$tile", mode: 'copy'

    """
    gdal_translate \
        -tr 100 100 -r average \
        $params.gdal.tran_opt_float \
        $mass temp.tif
    # t/m² -> kt/100m²
    gdal_calc.py \
        -A temp.tif \
        --calc="(A*10*10/1000)" \
        --outfile=mass_grand_total_kt_100m2.tif \
        $params.gdal.calc_opt_float
    """

}


process mass_grand_total_Mt_1km2 {

    label 'gdal'

    input:
    tuple val(tile), val(state), val(type), val(material), file(mass)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass_grand_total_Mt_1km2.tif')

    publishDir "$params.dir.pub/$state/$tile", mode: 'copy'

    """
    gdal_translate \
        -tr 1000 1000 -r average \
        $params.gdal.tran_opt_float \
        $mass temp.tif
    # kt/100m² -> Mt/km²
    gdal_calc.py \
        -A temp.tif \
        --calc="(A*10*10/1000)" \
        --outfile=mass_grand_total_Mt_1km2.tif \
        $params.gdal.calc_opt_float
    """

}


process mass_grand_total_Gt_10km2 {

    label 'gdal'
    
    input:
    tuple val(tile), val(state), val(type), val(material), file(mass)

    output:
    tuple val(tile), val(state), val(type), val(material), file('mass_grand_total_Gt_10km2.tif')

    publishDir "$params.dir.pub/$state/$tile", mode: 'copy'

    """
    gdal_translate \
        -tr 10000 10000 -r average \
        $params.gdal.tran_opt_float \
        $mass temp.tif
    # Mt/km² -> Gt/10km²
    gdal_calc.py \
        -A temp.tif \
        --calc="(A*10*10/1000)" \
        --outfile=mass_grand_total_Gt_10km2.tif \
        $params.gdal.calc_opt_float
    """

}

