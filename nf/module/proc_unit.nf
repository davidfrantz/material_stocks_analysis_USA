

// tuple with state and tile
workflow proc_unit {

    main:
    tile_lists = Channel.fromPath( params.dir.tiles + "/" + params.country_code + "_*.txt" )

    get_processing_units(tile_lists)

    emit:
    get_processing_units.out.splitCsv(header: false, sep: ",")

}


/** get processing units [tile, state] 
-----------------------------------------------------------------------**/


process get_processing_units {

    input:
    file tile_list

    output:
    stdout

    """
    list="$tile_list"
    state=\${list%%.*}
    cp $tile_list tmp
    sed "s/\$/,\$state/" tmp
    """
}

