/** zonal statistics
-----------------------------------------------------------------------**/

process zonal {

    label 'mem_2'

    input:
    tuple val(tile), val(state), 
        val(category), val(dimension), val(material), 
        val(basename), file(values), file(zones), val(pubdir)

    output:
    tuple val(tile), val(state), val(category), val(dimension), val(material), val(basename), file('*.csv') optional true

    publishDir "$pubdir", mode: 'copy'

    """
    zonal_stats_from_tiles.py $basename".csv" $values $zones
    """

}


process zonal_merge {

    input:
    tuple val(state), val(category), val(dimension),  val(material), val(basename), file('?.csv'), val(pubdir)

    output:
    tuple val(state), val(category), val(dimension),  val(material), val(basename), file('*.csv')

    publishDir "$pubdir", mode: 'copy'

    """
    raster_sum_stats.py $basename".csv" *.csv
    """

}
