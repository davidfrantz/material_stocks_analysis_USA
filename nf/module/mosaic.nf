
process stage_in_directory {

    input:
    tuple val(tile), val(state), 
        val(category), val(dimension), val(material), 
        val(basename), file("$reldir/*"), val(reldir) 

    output:
    tuple val(tile), val(state), 
        val(category), val(dimension), val(material), 
        val(basename), file("$tile")

    """
    touch $tile
    """

}


process mosaic {

    container 'davidfrantz/force:dev'

    input:
    tuple file('*'), val(dir_mosaic), val(pubdir)

    output:
    file("*.vrt")

    publishDir "$pubdir", mode: 'copy'

    """
    force-mosaic -m $dir_mosaic .
    mv $dir_mosaic/*.vrt .
    """

}

