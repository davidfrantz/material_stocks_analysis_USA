/** building volume per building type
-----------------------------------------------------------------------**/

include { multijoin }                          from './defs.nf'
include { finalize }                           from './finalize.nf'

include { volume as volume_building_lightweight           } from './volume.nf'
include { volume as volume_building_singlefamily          } from './volume.nf'
include { volume as volume_building_multifamily           } from './volume.nf'
include { volume as volume_building_commercial_industrial } from './volume.nf'
include { volume as volume_building_commercial_innercity  } from './volume.nf'
include { volume as volume_building_highrise              } from './volume.nf'
include { volume as volume_building_skyscraper            } from './volume.nf'


workflow volume_building {

    take:
    area_lightweight
    area_singlefamily
    area_multifamily
    area_commercial_industrial
    area_commercial_innercity
    area_highrise
    area_skyscraper
    height
    zone

    main:
    volume_building_lightweight(
        multijoin([area_lightweight, height], [0,1]))
    volume_building_singlefamily(
        multijoin([area_singlefamily, height], [0,1]))
    volume_building_multifamily(
        multijoin([area_multifamily, height], [0,1]))
    volume_building_commercial_industrial(
        multijoin([area_commercial_industrial, height], [0,1]))
    volume_building_commercial_innercity(
        multijoin([area_commercial_innercity, height], [0,1]))
    volume_building_highrise(
        multijoin([area_highrise, height], [0,1]))
    volume_building_skyscraper(
        multijoin([area_skyscraper, height], [0,1]))

    all_published = 
        volume_building_lightweight.out
        .mix(   volume_building_singlefamily.out,
                volume_building_multifamily.out,
                volume_building_commercial_industrial.out,
                volume_building_commercial_innercity.out,
                volume_building_highrise.out,
                volume_building_skyscraper.out)
        .map{
            [ it[0], it[1], "building", "volume", "", it[2].name, it[2] ] }

    finalize(all_published, zone)


    emit:
    lightweight           = volume_building_lightweight.out
    singlefamily          = volume_building_singlefamily.out
    multifamily           = volume_building_multifamily.out
    commercial_industrial = volume_building_commercial_industrial.out
    commercial_innercity  = volume_building_commercial_innercity.out
    highrise              = volume_building_highrise.out
    skyscraper            = volume_building_skyscraper.out

}

