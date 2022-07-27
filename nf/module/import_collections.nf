include { read_input_full_country; read_input_per_state; multijoin } from './defs.nf'

include { import_mask                                    } from './mask_collection.nf'
include { mask_collection_byte  as mask_street           } from './mask_collection.nf'
include { mask_collection_byte  as mask_street_brdtun    } from './mask_collection.nf'
include { mask_collection_byte  as mask_rail             } from './mask_collection.nf'
include { mask_collection_byte  as mask_rail_brdtun      } from './mask_collection.nf'
include { mask_collection_byte  as mask_apron            } from './mask_collection.nf'
include { mask_collection_byte  as mask_taxi             } from './mask_collection.nf'
include { mask_collection_byte  as mask_runway           } from './mask_collection.nf'
include { mask_collection_byte  as mask_parking          } from './mask_collection.nf'
include { mask_collection_byte  as mask_impervious       } from './mask_collection.nf'
include { mask_collection_byte  as mask_footprint        } from './mask_collection.nf'
include { mask_collection_int16 as mask_height           } from './mask_collection.nf'
include { mask_collection_int16 as mask_type             } from './mask_collection.nf'
include { mask_collection_byte  as mask_street_climate   } from './mask_collection.nf'
include { mask_collection_byte  as mask_building_climate } from './mask_collection.nf'
include { mask_collection_int16 as mask_zone             } from './mask_collection.nf'
include { mask_collection_int16 as mask_areacorr         } from './mask_collection.nf'
include { area_correction                                } from './area_correction.nf'



def import_collection_full_country(proc_unit, file_tuple){
    collection = read_input_full_country(file_tuple)
    collection = multijoin([proc_unit, collection], by = 0)
}

def import_collection_per_state(proc_unit, file_tuple){
    collection = read_input_per_state(file_tuple)
    collection = multijoin([proc_unit, collection], by = [0,1])
}


workflow collection {

    take: 
    proc_unit

    main:

    /** ingest all rasters into tupled channels [tile, state, file]
    -----------------------------------------------------------------------**/
    mask             = import_collection_per_state(proc_unit,    params.raster.mask)
    zone             = import_collection_full_country(proc_unit, params.raster.zone)
    street           = import_collection_full_country(proc_unit, params.raster.street)
    street_brdtun    = import_collection_full_country(proc_unit, params.raster.street_brdtun)
    rail             = import_collection_full_country(proc_unit, params.raster.rail)
    rail_brdtun      = import_collection_full_country(proc_unit, params.raster.rail_brdtun)
    apron            = import_collection_full_country(proc_unit, params.raster.apron)
    taxi             = import_collection_full_country(proc_unit, params.raster.taxi)
    runway           = import_collection_full_country(proc_unit, params.raster.runway)
    parking          = import_collection_full_country(proc_unit, params.raster.parking)
    impervious       = import_collection_full_country(proc_unit, params.raster.impervious)
    footprint        = import_collection_per_state(proc_unit,    params.raster.footprint)
    height           = import_collection_per_state(proc_unit,    params.raster.height)
    type             = import_collection_per_state(proc_unit,    params.raster.type)
    street_climate   = import_collection_full_country(proc_unit, params.raster.street_climate)
    building_climate = import_collection_full_country(proc_unit, params.raster.building_climate)
    areacorr         = import_collection_full_country(proc_unit, params.raster.areacorr)


    // import the masks
    mask = mask | import_mask

    // mask the rasters
    mask_street(multijoin([mask, street], [0,1]))
    mask_zone(multijoin([mask, zone], [0,1]))
    mask_street_brdtun(multijoin([mask, street_brdtun], [0,1]))
    mask_rail(multijoin([mask, rail], [0,1]))
    mask_rail_brdtun(multijoin([mask, rail_brdtun], [0,1]))
    mask_apron(multijoin([mask, apron], [0,1]))
    mask_taxi(multijoin([mask, taxi], [0,1]))
    mask_runway(multijoin([mask, runway], [0,1]))
    mask_parking(multijoin([mask, parking], [0,1]))
    mask_impervious(multijoin([mask, impervious], [0,1]))
    mask_footprint(multijoin([mask, footprint], [0,1]))
    mask_height(multijoin([mask, height], [0,1]))
    mask_type(multijoin([mask, type], [0,1]))
    mask_street_climate(multijoin([mask, street_climate], [0,1]))
    mask_building_climate(multijoin([mask, building_climate], [0,1]))
    mask_areacorr(multijoin([mask, areacorr], [0,1]))

    area =  mask_street.out
                .combine(Channel.from("street"))
                .mix(
            mask_street_brdtun.out
                .combine(Channel.from("street_brdtun")),
            mask_rail.out
                .combine(Channel.from("rail")),
            mask_rail_brdtun.out
                .combine(Channel.from("rail_brdtun")),
            mask_apron.out
                .combine(Channel.from("apron")),
            mask_taxi.out
                .combine(Channel.from("taxi")),
            mask_runway.out
                .combine(Channel.from("runway")),
            mask_parking.out
                .combine(Channel.from("parking")),
            mask_impervious.out
                .combine(Channel.from("impervious")),
            mask_footprint.out
                .combine(Channel.from("footprint"))
            )

    area_correction(multijoin([area, mask_areacorr.out], [0,1]))


    emit:
    zone             = mask_zone.out
    street           = area_correction.out
                        .filter{ it[3].equals('street')}
                        .map{ [ it[0], it[1], it[2] ] }
    street_brdtun    = area_correction.out
                        .filter{ it[3].equals('street_brdtun')}
                        .map{ [ it[0], it[1], it[2] ] }
    rail             = area_correction.out
                        .filter{ it[3].equals('rail')}
                        .map{ [ it[0], it[1], it[2] ] }
    rail_brdtun      = area_correction.out
                        .filter{ it[3].equals('rail_brdtun')}
                        .map{ [ it[0], it[1], it[2] ] }
    apron            = area_correction.out
                        .filter{ it[3].equals('apron')}
                        .map{ [ it[0], it[1], it[2] ] }
    taxi             = area_correction.out
                        .filter{ it[3].equals('taxi')}
                        .map{ [ it[0], it[1], it[2] ] }
    runway           = area_correction.out
                        .filter{ it[3].equals('runway')}
                        .map{ [ it[0], it[1], it[2] ] }
    parking          = area_correction.out
                        .filter{ it[3].equals('parking')}
                        .map{ [ it[0], it[1], it[2] ] }
    impervious       = area_correction.out
                        .filter{ it[3].equals('impervious')}
                        .map{ [ it[0], it[1], it[2] ] }
    footprint        = area_correction.out
                        .filter{ it[3].equals('footprint')}
                        .map{ [ it[0], it[1], it[2] ] }
    height           = mask_height.out
    type             = mask_type.out
    street_climate   = mask_street_climate.out
    building_climate = mask_building_climate.out

}

