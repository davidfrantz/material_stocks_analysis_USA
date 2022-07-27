/** building stock
-----------------------------------------------------------------------**/

include { multijoin; remove }                          from './defs.nf'
include { mass; mass_climate5 }                from './mass.nf'
include { finalize }                           from './finalize.nf'


workflow mass_building {

    take:
    lightweight; singlefamily; multifamily; 
    commercial_industrial; commercial_innercity; 
    highrise; skyscraper;
    climate; zone; mi


    main:

    // tile, state, file, type, material, mi
    lightweight = lightweight
    .combine( Channel.from("lightweight") )
    .combine( mi.map{ tab -> [tab.material, tab.lightweight] } )

    // tile, state, file, type, material, mi
    multifamily = multifamily
    .combine( Channel.from("multifamily") )
    .combine( mi.map{ tab -> [tab.material, tab.multifamily] } )

    // tile, state, file, type, material, mi
    commercial_industrial = commercial_industrial
    .combine( Channel.from("commercial_industrial") )
    .combine( mi.map{ tab -> [tab.material, tab.commercial_industrial] } )

    // tile, state, file, type, material, mi
    commercial_innercity = commercial_innercity
    .combine( Channel.from("commercial_innercity") )
    .combine( mi.map{ tab -> [tab.material, tab.commercial_innercity] } )

    // tile, state, file, type, material, mi
    highrise = highrise
    .combine( Channel.from("highrise") )
    .combine( mi.map{ tab -> [tab.material, tab.highrise] } )

    // tile, state, file, type, material, mi
    skyscraper = skyscraper
    .combine( Channel.from("skyscraper") )
    .combine( mi.map{ tab -> [tab.material, tab.skyscraper] } )


    // tile, state, file, type, material, mi, pubdir -> mass
    lightweight
    .mix(multifamily,
         commercial_industrial,
         commercial_innercity,
         highrise,
         skyscraper)
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/building/" + it[4]) } \
    | mass


    // tile, state, file, type, material, 5 x mi, pubdir -> mass_climate5
    multijoin([singlefamily, climate], [0,1])
    .combine( Channel.from("singlefamily") )
    .combine( mi.map{ tab -> [tab.material, 
              tab.singlefamily_climate1, tab.singlefamily_climate2, tab.singlefamily_climate3, 
              tab.singlefamily_climate4, tab.singlefamily_climate5] } )
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/building/" + it[5]) } \
    | mass_climate5


    // tile, state, type, material, 7 x files, pubdir -> mass_building_total
    multijoin([ 
        mass.out.filter{ it[2].equals('lightweight')}.map{ remove(it, 2) },
        mass_climate5.out.filter{ it[2].equals('singlefamily')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('multifamily')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('commercial_industrial')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('commercial_innercity')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('highrise')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('skyscraper')}.map{ remove(it, 2) }], 
        [0,1,2] )
    .filter{ it[2].equals('total')} \
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/building/" + it[2]) } \
    | mass_building_total


    // tile, state, category, dimension, material, basename, filename -> 1st channel of finalize
    all_published = mass_building_total.out
    .mix(mass.out,
         mass_climate5.out)
    .map{
        [ it[0], it[1], "building", "mass", it[3], it[4].name, it[4] ] }

    finalize(all_published, zone)


    emit:
    total = mass_building_total.out

}


process mass_building_total {

    label 'gdal'
    label 'mem_7'

    input:
    tuple val(tile), val(state), val(material), 
        file(lightweight), file(singlefamily), file(multifamily), 
        file(commercial_industrial), file(commercial_innercity), 
        file(highrise), file(skyscraper), val(pubdir)

    output:
    tuple val(tile), val(state), val("total"), val(material), file('mass_building_total.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    gdal_calc.py \
        -A $lightweight \
        -B $singlefamily \
        -C $multifamily \
        -D $commercial_industrial \
        -E $commercial_innercity \
        -F $highrise \
        -G $skyscraper \
        --calc="(A+B+C+D+E+F+G)" \
        --outfile=mass_building_total.tif \
        $params.gdal.calc_opt_float
    """

}


