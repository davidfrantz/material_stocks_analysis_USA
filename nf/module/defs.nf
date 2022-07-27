/**-----------------------------------------------------------------------
--- DEFINITIONS ----------------------------------------------------------
-----------------------------------------------------------------------**/
 // djj
def remove( list_it, index){
  def new_list = list_it[0..-1]
  new_list.remove(index)
  return new_list
}

// extract basename of parent directory
def extractDirectory(it) { 
    it.parent.toString()
    .substring(
        it.parent.toString()
        .lastIndexOf('/') + 1 
    )
}

// read raster collection that is provided for full country at once
def read_input_full_country(file_tuple){
    Channel.of(file(file_tuple[0] + "/*/" + file_tuple[1]))
    .flatten()
    .map{
        [
            extractDirectory(it),
            it
        ]
    }
}

// read raster collection that is provided per federal state
def read_input_per_state(file_tuple){
    Channel.of(file(file_tuple[0] + "/*/*" + file_tuple[1]))
    .flatten()
    .map{
        [
            extractDirectory(it), 
            it.name.substring(0,it.name.indexOf(file_tuple[1])-1), 
            it
        ]
    }
}


// read table, split columns to tuples
def read_table(file_tuple, sep, header){
    Channel.of(file(file_tuple[0] + "/" + file_tuple[1]))
    //.splitText()
    .splitCsv(sep: sep, header: header)
}

// join multiple channels based on one or several keys
def multijoin(x, by){
    def result = x[0];
    int i;
    for(i=1 ; i < x.size(); i++){
        result = result.combine(x[i], by: by)
    }
    return result
}

