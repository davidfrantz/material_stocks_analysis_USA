#!/usr/bin/env nextflow

// enable modules
nextflow.enable.dsl=2


/**-----------------------------------------------------------------------
--- PARAMETERS, PATHS, OPTIONS AND THRESHOLDS ----------------------------
-----------------------------------------------------------------------**/

// country
params.country      = "USA"
params.country_code = "US"

// project directory
params.dir_project = "/data/ahsoka/gi-sds/hub/mat_stocks"

// directories
params.dir = [
    "tiles":      params.dir_project + "/tiles/"    + params.country,
    "mask":       params.dir_project + "/mask/"     + params.country,
    "zone":       params.dir_project + "/zone/"     + params.country,
    "osm":        params.dir_project + "/osm/"      + params.country,
    "type":       params.dir_project + "/type/"     + params.country,
    "impervious": params.dir_project + "/fraction/" + params.country,
    "footprint":  params.dir_project + "/building/" + params.country,
    "height":     params.dir_project + "/height/"   + params.country,
    "climate":    params.dir_project + "/climate/"  + params.country,
    "pub":        params.dir_project + "/stock_v2/" + params.country,
    "mi":         params.dir_project + "/mi/"       + params.country,
    "areacorr":   params.dir_project + "/areacorr/" + params.country
]

// raster collections
params.raster = [
    "mask":             [params.dir.mask,       "5km.tif"],
    "zone":             [params.dir.zone,       "counties-usgov-5km.tif"],
    "street":           [params.dir.osm,        "streets.tif"],
    "street_brdtun":    [params.dir.osm,        "road-brdtun.tif"],
    "rail":             [params.dir.osm,        "railway.tif"],
    "rail_brdtun":      [params.dir.osm,        "rail-brdtun.tif"],
    "apron":            [params.dir.osm,        "apron.tif"],
    "taxi":             [params.dir.osm,        "taxiway.tif"],
    "runway":           [params.dir.osm,        "runway.tif"],
    "parking":          [params.dir.osm,        "parking.tif"],
    "impervious":       [params.dir.impervious, "NLCD_2016_Impervious_L48_20190405_canada-cleaned.tif"],
    "footprint":        [params.dir.footprint,  "building.tif"],
    "height":           [params.dir.height,     "BUILDING-HEIGHT_HL_ML_MLP.tif"],
    "type":             [params.dir.type,       "BUILDING-TYPE_HL_ML_MLP.tif" ],
    "street_climate":   [params.dir.climate,    "road_climate.tif"],
    "building_climate": [params.dir.climate,    "building_climate.tif"],
    "areacorr":         [params.dir.areacorr,   "true_area.tif"]
]

// MI files
params.mi = [
    "building": [params.dir.mi, "building_v6.csv"], 
    "street":   [params.dir.mi, "street_v6.csv"], 
    "rail":     [params.dir.mi, "rail_v6.csv"], 
    "other":    [params.dir.mi, "other_v6.csv"], 
]


params.class = [
    // building type classes (mapped)
    "res":        1,
    "comm_ind":   3,
    "comm_cbd":   5,
    "mobile":     6,

    // additional bulding type classes (set within workflow)
    "res_sf":     1,
    "res_mf":     2,
    "highrise":   8,
    "skyscraper": 9
]

params.threshold = [
    // height thresholds
    "height_building":   2,
    "height_mf":         10,
    "height_highrise":   30,
    "height_skyscraper": 75,

    // area thresholds
    "area_impervious":   50,
    "percent_garage":    0.1
]

// scaling factors
params.scale = [
    "height": 10
]

// options for gdal
params.gdal = [
    "calc_opt_byte":  '--NoDataValue=255   --type=Byte    --format=GTiff --creation-option=INTERLEAVE=BAND --creation-option=COMPRESS=LZW --creation-option=PREDICTOR=2 --creation-option=BIGTIFF=YES --creation-option=TILED=YES',
    "calc_opt_int16": '--NoDataValue=-9999 --type=Int16   --format=GTiff --creation-option=INTERLEAVE=BAND --creation-option=COMPRESS=LZW --creation-option=PREDICTOR=2 --creation-option=BIGTIFF=YES --creation-option=TILED=YES',
    "calc_opt_float": '--NoDataValue=-9999 --type=Float32 --format=GTiff --creation-option=INTERLEAVE=BAND --creation-option=COMPRESS=LZW --creation-option=PREDICTOR=2 --creation-option=BIGTIFF=YES --creation-option=TILED=YES',
    "tran_opt_float": '-a_nodata -9999 -ot Float32 -of GTiff  -co INTERLEAVE=BAND -co COMPRESS=LZW -co PREDICTOR=2 -co BIGTIFF=YES -co TILED=YES'
]



/**-----------------------------------------------------------------------
--- INCLUDE MODULES ------------------------------------------------------
-----------------------------------------------------------------------**/

include { multijoin }                       from './module/defs.nf'
include { proc_unit }                       from './module/proc_unit.nf'
include { collection }                      from './module/import_collections.nf'
include { mi }                              from './module/import_mi.nf'
include { area_street }                     from './module/area_street.nf'
include { area_rail }                       from './module/area_rail.nf'
include { area_other }                      from './module/area_other.nf'
include { area_aboveground_infrastructure } from './module/area_aboveground_infrastructure.nf'
include { property_building }               from './module/property_building.nf'
include { area_building }                   from './module/area_building.nf'
include { volume_building }                 from './module/volume_building.nf'
include { area_impervious }                 from './module/area_impervious.nf'
include { mass_street }                     from './module/mass_street.nf'
include { mass_rail }                       from './module/mass_rail.nf'
include { mass_other }                      from './module/mass_other.nf'
include { mass_building }                   from './module/mass_building.nf'
include { mass_grand_total }                from './module/mass_grand_total.nf'


/**-----------------------------------------------------------------------
--- START OF WORKFLOW ----------------------------------------------------
-----------------------------------------------------------------------**/

workflow {

    // get processing units (tile / state)
    proc_unit()
 
    // import raster collections
    collection(proc_unit.out)

    // import material intensity factors
    mi()

    // area of street types
    area_street(
        collection.out.street, 
        collection.out.street_brdtun,
        collection.out.zone)

    // area of rail types
    area_rail(
        collection.out.rail, 
        collection.out.rail_brdtun,
        collection.out.zone)
 
    // area of other infrastructure types
    area_other(
        collection.out.apron, 
        collection.out.taxi,
        collection.out.runway, 
        collection.out.parking,
        collection.out.zone)

    // area of aboveground infrastructure
    area_aboveground_infrastructure(
        area_street.out.motorway,
        area_street.out.primary,
        area_street.out.secondary,
        area_street.out.tertiary,
        area_street.out.local,
        area_street.out.track,
        area_street.out.exclude,
        area_street.out.motorway_elevated,
        area_street.out.other_elevated,
        area_street.out.bridge_motorway,
        area_street.out.bridge_other,
        area_street.out.tunnel,
        area_rail.out.railway,
        area_rail.out.tram,
        area_rail.out.other,
        area_rail.out.exclude,
        area_rail.out.subway_elevated,
        area_rail.out.subway_surface,
        area_rail.out.bridge,
        area_rail.out.tunnel,
        area_other.out.airport,
        area_other.out.parking)

    // building properties
    property_building(
        collection.out.height, 
        collection.out.footprint, 
        collection.out.type)

    // area of building types
    area_building(
        property_building.out.area,
        property_building.out.type,
        collection.out.zone)

    // volume of building types
    volume_building(
        area_building.out.lightweight,
        area_building.out.singlefamily,
        area_building.out.multifamily,
        area_building.out.commercial_industrial,
        area_building.out.commercial_innercity,
        area_building.out.highrise,
        area_building.out.skyscraper,
        property_building.out.height,
        collection.out.zone)

    // area of remaining impervious infrastructure
    area_impervious(
        collection.out.impervious,
        property_building.out.area,
        area_aboveground_infrastructure.out.total,
        collection.out.zone)


    // mass of streets
    mass_street(
        area_street.out.motorway,
        area_street.out.primary,
        area_street.out.secondary,
        area_street.out.tertiary,
        area_street.out.local,
        area_street.out.track,
        area_street.out.motorway_elevated,
        area_street.out.other_elevated,
        area_street.out.bridge_motorway,
        area_street.out.bridge_other,
        area_street.out.tunnel,
        collection.out.street_climate,
        collection.out.zone,
        mi.out.street,
    )


    // mass of rails
    mass_rail(
        area_rail.out.railway,
        area_rail.out.tram,
        area_rail.out.subway,
        area_rail.out.subway_elevated,
        area_rail.out.subway_surface,
        area_rail.out.other,
        area_rail.out.bridge,
        area_rail.out.tunnel,
        collection.out.zone,
        mi.out.rail
    )


    // mass of other infrastructure
    mass_other(
        area_other.out.airport,
        area_other.out.parking,
        area_impervious.out.remaining,
        collection.out.zone,
        mi.out.other
    )


    // mass of buildings
    mass_building(
        volume_building.out.lightweight,
        volume_building.out.singlefamily,
        volume_building.out.multifamily,
        volume_building.out.commercial_industrial,
        volume_building.out.commercial_innercity,
        volume_building.out.highrise,
        volume_building.out.skyscraper,
        collection.out.building_climate,
        collection.out.zone,
        mi.out.building
    )


    // total techno-mass
    mass_grand_total(
        mass_street.out.total,
        mass_rail.out.total,
        mass_other.out.total,
        mass_building.out.total,
        collection.out.zone
    )

}
