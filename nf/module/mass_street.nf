/** street stock
-----------------------------------------------------------------------**/

include { multijoin; remove }                  from './defs.nf'
include { mass; mass_climate6 }                from './mass.nf'
include { finalize }                           from './finalize.nf'


workflow mass_street {

    take:
    motorway; primary; secondary; tertiary;
    local; track; motorway_elevated; other_elevated
    bridge_motorway; bridge_other; tunnel;
    climate; zone; mi


    main:

    // tile, state, file, type, material, mi
    motorway = motorway
    .combine( Channel.from("motorway") )
    .combine( mi.map{ tab -> [tab.material, tab.motorway]} )

    // tile, state, file, type, material, mi
    primary = primary
    .combine( Channel.from("primary") )
    .combine( mi.map{ tab -> [tab.material, tab.primary]} )

    // tile, state, file, type, material, mi
    secondary = secondary
    .combine( Channel.from("secondary") )
    .combine( mi.map{ tab -> [tab.material, tab.secondary]} )

    // tile, state, file, type, material, mi
    tertiary = tertiary
    .combine( Channel.from("tertiary") )
    .combine( mi.map{ tab -> [tab.material, tab.tertiary]} )

    // tile, state, file, type, material, mi
    motorway_elevated = motorway_elevated
    .combine( Channel.from("motorway_elevated") )
    .combine( mi.map{ tab -> [tab.material, tab.motorway_elevated]} )

    // tile, state, file, type, material, mi
    other_elevated = other_elevated
    .combine( Channel.from("other_elevated") )
    .combine( mi.map{ tab -> [tab.material, tab.other_elevated]} )

    // tile, state, file, type, material, mi
    bridge_motorway = bridge_motorway
    .combine( Channel.from("bridge_motorway") )
    .combine( mi.map{ tab -> [tab.material, tab.bridge_motorway]} )

    // tile, state, file, type, material, mi
    bridge_other = bridge_other
    .combine( Channel.from("bridge_other") )
    .combine( mi.map{ tab -> [tab.material, tab.bridge_other]} )

    // tile, state, file, type, material, mi
    tunnel = tunnel
    .combine( Channel.from("tunnel") )
    .combine( mi.map{ tab -> [tab.material, tab.tunnel]} )


    // tile, state, file, type, material, mi, pubdir -> mass
    motorway
    .mix(primary,
         secondary,
         tertiary,
         motorway_elevated,
         other_elevated,
         bridge_motorway,
         bridge_other,
         tunnel)
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/street/" + it[4]) } \
    | mass


    // tile, state, file, type, material, 6 x mi
    local = multijoin([local, climate], [0,1])
    .combine( Channel.from("local") )
    .combine( mi.map{ tab -> [tab.material, 
              tab.local_climate1, tab.local_climate2, tab.local_climate3, 
              tab.local_climate4, tab.local_climate5, tab.local_climate6]} )

    // tile, state, file, type, material, 6 x mi
    track = multijoin([track, climate], [0,1])
    .combine( Channel.from("track") )
    .combine( mi.map{ tab -> [tab.material, 
              tab.track_climate1, tab.track_climate2, tab.track_climate3, 
              tab.track_climate4, tab.track_climate5, tab.track_climate6]} )


    // tile, state, file, type, material, 6 x mi, pubdir -> mass_climate6
    local
    .mix(track)
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/street/" + it[5]) } \
    | mass_climate6


    // tile, state, type, material, 11 x files, pubdir -> mass_building_total
    multijoin([ 
        mass.out.filter{ it[2].equals('motorway')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('primary')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('secondary')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('tertiary')}.map{ remove(it, 2) },
        mass_climate6.out.filter{ it[2].equals('local')}.map{ remove(it, 2) },
        mass_climate6.out.filter{ it[2].equals('track')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('motorway_elevated')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('other_elevated')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('bridge_motorway')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('bridge_other')}.map{ remove(it, 2) },
        mass.out.filter{ it[2].equals('tunnel')}.map{ remove(it, 2) }],
        [0,1,2] )
    .filter{ it[2].equals('total')} \
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1,0].join("/") + "/mass/street/" + it[2]) } \
    | mass_street_total


    // tile, state, category, dimension, material, basename, filename -> 1st channel of finalize
    all_published = mass_street_total.out
    .mix(mass.out,
         mass_climate6.out)
    .map{
        [ it[0], it[1], "street", "mass", it[3], it[4].name, it[4] ] }

    finalize(all_published, zone)


    emit:
    total = mass_street_total.out

}


process mass_street_total {

    label 'gdal'
    label 'mem_11'

    input:
    tuple val(tile), val(state), val(material), 
        file(motorway), file(primary), file(secondary), file(tertiary), 
        file(local), file(track), file(motorway_elevated), 
        file(other_elevated), file(bridge_motorway), 
        file(bridge_other), file(tunnel), val(pubdir)

    output:
    tuple val(tile), val(state), val("total"), val(material), file('mass_street_total.tif')

    publishDir "$pubdir", mode: 'copy'

    """
    gdal_calc.py \
        -A $motorway \
        -B $primary \
        -C $secondary \
        -D $tertiary \
        -E $local \
        -F $track \
        -G $motorway_elevated \
        -H $other_elevated \
        -I $bridge_motorway \
        -J $bridge_other \
        -K $tunnel \
        --calc="(A+B+C+D+E+F+G+H+I+J+K)" \
        --outfile=mass_street_total.tif \
        $params.gdal.calc_opt_float
    """

}

