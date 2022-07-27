/** rail stock
-----------------------------------------------------------------------**/

include { multijoin; remove }                          from './defs.nf'
include { mass }                               from './mass.nf'
include { finalize }                           from './finalize.nf'


workflow mass_rail {

    take:
    railway; tram; subway; 
    subway_elevated; subway_surface; 
    other; bridge; tunnel;
    zone; mi


    main:

    // tile, state, file, type, material, mi
    railway = railway
    .combine( Channel.from("railway") )
    .combine( mi.map{ tab -> [tab.material, tab.railway] } )

    // tile, state, file, type, material, mi
    tram = tram
    .combine( Channel.from("tram") )
    .combine( mi.map{ tab -> [tab.material, tab.tram] } )

    // tile, state, file, type, material, mi
    subway = subway
    .combine( Channel.from("subway") )
    .combine( mi.map{ tab -> [tab.material, tab.subway] } )

    // tile, state, file, type, material, mi
    subway_elevated = subway_elevated
    .combine( Channel.from("subway_elevated") )
    .combine( mi.map{ tab -> [tab.material, tab.subway_elevated] } )

    // tile, state, file, type, material, mi
    subway_surface = subway_surface
    .combine( Channel.from("subway_surface") )
    .combine( mi.map{ tab -> [tab.material, tab.subway_surface] } )

    // tile, state, file, type, material, mi
    other = other
    .combine( Channel.from("other") )
    .combine( mi.map{ tab -> [tab.material, tab.other] } )

    // tile, state, file, type, material, mi
    bridge = bridge
    .combine( Channel.from("bridge") )
    .combine( mi.map{ tab -> [tab.material, tab.bridge] } )

    // tile, state, file, type, material, mi
    tunnel = tunnel
    .combine( Channel.from("tunnel") )
    .combine( mi.map{ tab -> [tab.material, tab.tunnel] } )


    // tile, state, file, type, material, mi, pubdir -> mass
    railway
    .mix(tram,
         subway,
         subway_elevated,
         subway_surface,
         other,
         bridge,
         tunnel)
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/rail/" + it[4]) } \
    | mass


    // tile, state, type, material, 8 x files, pubdir -> mass_building_total
    multijoin([
        mass.out.filter{ it[2].equals('railway')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('tram')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('subway')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('subway_elevated')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('subway_surface')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('other')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('bridge')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('tunnel')}.map{ remove(it, 2) }],
        [0,1,2] )
    .filter{ it[2].equals('total')} \
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/rail/" + it[2]) } \
    | mass_rail_total


    // tile, state, category, dimension, material, basename, filename -> 1st channel of finalize
    all_published = mass_rail_total.out
    .mix(mass.out)
    .map{
        [ it[0], it[1], "rail", "mass", it[3], it[4].name, it[4] ] }

    finalize(all_published, zone)


    emit:
    total = mass_rail_total.out

}


process mass_rail_total {

    label 'gdal'
    label 'mem_8'

    input:
    tuple val(tile), val(state), val(material), 
        file(railway), file(tram), file(subway), 
        file(subway_elevated), file(subway_surface), 
        file(other), file(bridge), file(tunnel), val(pubdir)

    output:
    tuple val(tile), val(state), val("total"), val(material), file('mass_rail_total.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    gdal_calc.py \
        -A $railway \
        -B $tram \
        -C $subway \
        -D $subway_elevated \
        -E $subway_surface \
        -F $other \
        -G $bridge \
        -H $tunnel \
        --calc="(A+B+C+D+E+F+G+H)" \
        --outfile=mass_rail_total.tif \
        $params.gdal.calc_opt_float
    """

}

