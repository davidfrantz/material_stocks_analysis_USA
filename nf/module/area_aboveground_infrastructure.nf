/** area of aboveground infrastructure
-----------------------------------------------------------------------**/

include { multijoin } from './defs.nf'


workflow area_aboveground_infrastructure {

    take:
    street_motorway
    street_primary
    street_secondary
    street_tertiary
    street_local
    street_track
    street_exclude
    street_motorway_elevated
    street_other_elevated
    street_bridge_motorway
    street_bridge_other
    street_tunnel
    rail_railway
    rail_tram
    rail_other
    rail_exclude
    rail_subway_elevated
    rail_subway_surface
    rail_bridge
    rail_tunnel
    other_airport
    other_parking


    main:
    area_ag_street_infrastructure(
        multijoin(
           [street_motorway, street_primary, street_secondary, 
            street_tertiary, street_local, street_track, 
            street_exclude, street_motorway_elevated, 
            street_other_elevated, street_bridge_motorway, 
            street_bridge_other, street_tunnel], [0,1])
    )

    area_ag_rail_infrastructure(
         multijoin(
           [rail_railway, 
            rail_tram,
            rail_other, 
            rail_exclude, 
            rail_subway_elevated, 
            rail_subway_surface, 
            rail_bridge, 
            rail_tunnel], [0,1])
    )

    area_ag_other_infrastructure(
        multijoin(
            [other_airport, other_parking], [0,1])
    )

    area_ag_total_infrastructure(
        multijoin(
           [area_ag_street_infrastructure.out, 
            area_ag_rail_infrastructure.out, 
            area_ag_other_infrastructure.out], [0,1])
    )

    emit:
    total = area_ag_total_infrastructure.out

}


// area [m²] of all aboveground street infrastructure
// if streets are in tunnels, subtract the tunnel area
// bridges come on top
process area_ag_street_infrastructure {

    label 'gdal'
    label 'mem_12'

    input:
    tuple val(tile), val(state), 
          file(motorway), file(primary), file(secondary), 
          file(tertiary), file(local), file(track), file(exclude), 
          file(motorway_elevated), file(other_elevated), 
          file(bridge_motorway), file(bridge_other), file(tunnel)

    output:
    tuple val(tile), val(state), file('area_ag_street_infrastructure.tif')

    """
    gdal_calc.py \
        -A $motorway \
        -B $primary \
        -C $secondary \
        -D $tertiary \
        -E $local \
        -F $track \
        -G $exclude \
        -H $motorway_elevated \
        -I $other_elevated \
        -J $bridge_motorway \
        -K $bridge_other \
        -Z $tunnel \
        --calc='minimum((maximum((single(A+B+C+D+E+F+G)-Z),0)+(H+I+J+K)),100)' \
        --outfile=area_ag_street_infrastructure.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of all aboveground rail infrastructure
// this includes aboveground subways
// if rails are in tunnels, subtract the tunnel area
// bridges come on top
process area_ag_rail_infrastructure {

    label 'gdal'
    label 'mem_8'

    input:
    tuple val(tile), val(state), 
          file(rail), file(tram), file(other), 
          file(exclude), file(subway_elevated), 
          file(subway_surface), file(bridge), 
          file(tunnel)

    output:
    tuple val(tile), val(state), file('area_ag_rail_infrastructure.tif')

    """
    gdal_calc.py \
        -A $rail \
        -B $tram \
        -C $other \
        -D $exclude \
        -E $subway_elevated \
        -F $subway_surface \
        -G $bridge \
        -Z $tunnel \
        --calc='minimum((maximum((single(A+B+C+D+F)-Z),0)+(E+G)),100)' \
        --outfile=area_ag_rail_infrastructure.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of other aboveground infrastructure
// other = airport and parking
process area_ag_other_infrastructure {

    label 'gdal'
    label 'mem_2'

    input:
    tuple val(tile), val(state), file(airport), file(parking)

    output:
    tuple val(tile), val(state), file('area_ag_other_infrastructure.tif')

    """
    gdal_calc.py \
        -A $airport \
        -B $parking \
        --calc='minimum((A+B),100)' \
        --outfile=area_ag_other_infrastructure.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of all aboveground infrastructure
process area_ag_total_infrastructure {

    label 'gdal'
    label 'mem_3'

    input:
    tuple val(tile), val(state), file(street), file(rail), file(other)

    output:
    tuple val(tile), val(state), file('area_ag_total_infrastructure.tif')

    """
    gdal_calc.py \
        -A $street \
        -B $rail \
        -C $other \
        --calc='minimum((A+B+C),100)' \
        --outfile=area_ag_total_infrastructure.tif \
        $params.gdal.calc_opt_byte
    """

}

 