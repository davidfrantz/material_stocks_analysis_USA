include { multijoin }                          from './defs.nf'
include { pyramid }                            from './pyramid.nf'
include { zonal }                              from './zonal.nf'
include { zonal_merge as zonal_merge_state   } from './zonal.nf'
include { zonal_merge as zonal_merge_country } from './zonal.nf'
include { stage_in_directory; mosaic         } from './mosaic.nf'


workflow finalize {

    take:
    input; zone
    /**      0    1     2        3         4        5        6
    input: tile state category dimension material basename filename
    zone:  tile state filename
    **/

    main:

    // pyramid takes filename, pubdir
    input
    .map{ [ it[6], "$params.dir.pub/" + it[1,0,3,2,4].join("/") ] }
    | pyramid

    // stage_in_directory takes relative pubdir, tile, state, category, dimension, material, basename, filename
    input
    .map{ it[0..-1].plus(it[0,3,2,4].join("/")) } \
    | stage_in_directory

    stage_in_directory.out
    .map{ it[0..-1]
          .plus("mosaic/" + it[3,2,4].join("/") ) }
    .map{ it[0..-1]
          .plus("$params.dir.pub/" + it[1] + "/mosaic/" + it[3,2,4].join("/") ) }
    .groupTuple(by: [1,5])
    .map{ [ it[6], it[7].first(), it[8].first() ] } \
    | mosaic


    // zonal takes tile, state, category, dimension, material, basename, filename, zones, pubdir
    multijoin([input, zone], [0,1])
    .map{ it[0..7]
          .plus("$params.dir.pub/" + it[1,0,3,2,4].join("/") ) } \
    | zonal

    // zonal_merge takes state, category, dimension, material, basename, filename, zones, pubdir
    zonal.out
    .map{ it[1..6]
          .plus("$params.dir.pub/" + it[1] + "/mosaic/" + it[3,2,4].join("/") ) }
    .groupTuple(by: [0,1,2,3,4,6]) \
    | zonal_merge_state

    // zonal_merge takes state, category, dimension, material, basename, filename, zones, pubdir
    zonal_merge_state.out
    .map{ it[0..5]
          .plus("$params.dir.pub/ALL/" + it[2,1,3].join("/") ) }
    .groupTuple(by: [1,2,3,4,6]) \
    | zonal_merge_country

}
