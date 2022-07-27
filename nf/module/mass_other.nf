/** other stock
-----------------------------------------------------------------------**/

include { multijoin; remove }                          from './defs.nf'
include { mass }                               from './mass.nf'
include { finalize }                           from './finalize.nf'


workflow mass_other {

    take:
    airport; parking; remaining;
    zone; mi


    main:

    // tile, state, file, type, material, mi
    airport = airport
    .combine( Channel.from("airport") )
    .combine( mi.map{ tab -> [tab.material, tab.airport] } )

    // tile, state, file, type, material, mi
    parking = parking
    .combine( Channel.from("parking") )
    .combine( mi.map{ tab -> [tab.material, tab.parking] } )
    
    // tile, state, file, type, material, mi
    remaining = remaining
    .combine( Channel.from("remaining") )
    .combine( mi.map{ tab -> [tab.material, tab.impervious] } )


    // tile, state, file, type, material, mi, pubdir -> mass
    airport
    .mix(parking,
         remaining)
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/other/" + it[4]) } \
    | mass


    // tile, state, type, material, 3 x files, pubdir -> mass_other_total
    multijoin([ 
        mass.out.filter{ it[2].equals('airport')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('parking')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('remaining')}.map{ remove(it, 2) }], 
        [0,1,2] )
    .filter{ it[2].equals('total')} \
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/other/" + it[2]) } \
    | mass_other_total


    // tile, state, category, dimension, material, basename, filename -> 1st channel of finalize
    all_published = mass_other_total.out
    .mix(mass.out)
    .map{
        [ it[0], it[1], "other", "mass", it[3], it[4].name, it[4] ] }

    finalize(all_published, zone)


    emit:
    total = mass_other_total.out

}


process mass_other_total {

    label 'gdal'
    label 'mem_3'

    input:
    tuple val(tile), val(state), val(material), 
        file(airport), file(parking), file(remaining), val(pubdir)

    output:
    tuple val(tile), val(state), val("total"), val(material), file('mass_other_total.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    gdal_calc.py \
        -A $airport \
        -B $parking \
        -C $remaining \
        --calc="(A+B+C)" \
        --outfile=mass_other_total.tif \
        $params.gdal.calc_opt_float
    """

}

