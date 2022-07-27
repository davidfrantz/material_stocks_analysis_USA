/** ingest all MI tables into tupled channels [material, mi]
-----------------------------------------------------------------------**/

include { read_table } from './defs.nf'


workflow mi {

    emit:
    building = read_table(params.mi.building, sep=",", header=true)
    street   = read_table(params.mi.street,   sep=",", header=true)
    rail     = read_table(params.mi.rail,     sep=",", header=true)
    other    = read_table(params.mi.other,    sep=",", header=true)

}

