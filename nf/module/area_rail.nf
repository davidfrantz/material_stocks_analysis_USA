/** area for rail types
-----------------------------------------------------------------------**/

include { multijoin }                          from './defs.nf'
include { finalize }                           from './finalize.nf'


workflow area_rail {

    take:
    rail; rail_brdtun; zone

    main:
    area_rail_railway(rail)
    area_rail_tram(rail)
    area_rail_other(rail)
    area_rail_exclude(rail)
    area_rail_subway(rail)
    area_rail_subway_elevated(rail)
    area_rail_subway_surface(rail)
    area_rail_bridge(rail_brdtun)
    area_rail_tunnel(multijoin([rail_brdtun, rail], [0,1]))

    all_published = 
        area_rail_railway.out
        .mix(   area_rail_tram.out,
                area_rail_other.out,
                area_rail_exclude.out,
                area_rail_subway.out,
                area_rail_subway_elevated.out,
                area_rail_subway_surface.out,
                area_rail_bridge.out,
                area_rail_tunnel.out)
        .map{
            [ it[0], it[1], "rail", "area", "", it[2].name, it[2] ] }

    finalize(all_published, zone)


    emit:
    railway         = area_rail_railway.out
    tram            = area_rail_tram.out
    other           = area_rail_other.out
    exclude         = area_rail_exclude.out
    subway          = area_rail_subway.out
    subway_elevated = area_rail_subway_elevated.out
    subway_surface  = area_rail_subway_surface.out
    bridge          = area_rail_bridge.out
    tunnel          = area_rail_tunnel.out

}


// rasterized OSM rail layer (area [m²])
/** 15 bands
 1  rail                         -> railway
 2  abandoned                    -> exclude
 3  disused                      -> other
 4  tram                         -> tram
 5  light_rail                   -> railway
 6  subway                       -> subway
 7  narrow_gauge                 -> other
 8  preserved                    -> other
 9  platform                     -> exclude
10  construction                 -> exclude
11  subway ground (bridge)       -> subway_elevated
12  subway ground(surface level) -> subway_surface
13  funicular                    -> other
14  monorail                     -> other
15  miniature                    -> other
**/


// rasterized OSM rail bridges/tunnel layer (area [m²])
/** 2 bands
1  Rail bridge -> bridge
2  Rail tunnel -> tunnel
**/


// area [m²] of regular rails
process area_rail_railway {

    label 'gdal'
    label 'mem_2'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_railway.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=1 \
        -B $rail --B_band=5 \
        --calc='minimum((A+B),100)' \
        --outfile=area_rail_railway.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of trams
process area_rail_tram {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_tram.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=4 \
        --calc='minimum(A,100)' \
        --outfile=area_rail_tram.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of other rail types
process area_rail_other {

    label 'gdal'
    label 'mem_6'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_other.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=3 \
        -B $rail --B_band=7 \
        -C $rail --C_band=8 \
        -D $rail --D_band=13 \
        -E $rail --E_band=14 \
        -F $rail --F_band=15 \
        --calc='minimum((A+B+C+D+E+F),100)' \
        --outfile=area_rail_other.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of rails with no man-made material (decommissioned)
// - should be subtracted from impervious surfaces,
// - but should not be assigned with a mass
process area_rail_exclude {

    label 'gdal'
    label 'mem_3'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_exclude.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=2 \
        -B $rail --B_band=9 \
        -C $rail --C_band=10 \
        --calc='minimum((A+B+C),100)' \
        --outfile=area_rail_exclude.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of underground subways (with tube)
process area_rail_subway {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_subway.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=6 \
        --calc='minimum(A,100)' \
        --outfile=area_rail_subway.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of aboveground subway rails on pillars
process area_rail_subway_elevated {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_subway_elevated.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=11 \
        --calc='minimum(A,100)' \
        --outfile=area_rail_subway_elevated.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of aboveground subway rails
process area_rail_subway_surface {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_subway_surface.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=12 \
        --calc='minimum(A,100)' \
        --outfile=area_rail_subway_surface.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of rail bridges (excluding the road)
process area_rail_bridge {

    label 'gdal'

    input:
    tuple val(tile), val(state), file(rail)

    output:
    tuple val(tile), val(state), file('area_rail_bridge.tif') 
    
    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $rail --A_band=1 \
        --calc='minimum(A,100)' \
        --outfile=area_rail_bridge.tif \
        $params.gdal.calc_opt_byte
    """

}


// area [m²] of rail tunnels (excluding the road)
process area_rail_tunnel {

    label 'gdal'
    
    input:
    tuple val(tile), val(state), file(tunnel), file(subway)

    output:
    tuple val(tile), val(state), file('area_rail_tunnel.tif') 

    publishDir "$params.dir.pub/$state/$tile/area/rail", mode: 'copy'

    """
    gdal_calc.py \
        -A $tunnel --A_band=2 \
        -B $subway --B_band=6 \
        --calc='minimum(maximum(A-B, 0),100)' \
        --outfile=area_rail_tunnel.tif \
        $params.gdal.calc_opt_byte
    """

}

