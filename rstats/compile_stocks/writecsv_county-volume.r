# this script tabulates 
# the volume of all structural categories for all counties

require(dplyr)
require(tidyr)

# input dir (stocks mapping)
dstock <- sprintf("/data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/ALL/volume")

# output dir (tabulated stocks)
dcsv <- "csv"


files <-    dstock %>%
            dir(".csv", full.names = TRUE, recursive = TRUE)
nfiles <-   length(files)
values <-   lapply(files,
                function(x) read.csv(x, sep = ";"))
rfiles <-   files %>% gsub(dstock, "", .)
labels <-   basename(files) %>%
            gsub("\\..*", "", .)

df <- values[[1]]
for (i in 2:nfiles) {
    df <- df %>% 
        full_join(values[[i]], by = "zone")
}

str(df)
colnames(df) <- c("zone", labels)

dir.create(sprintf("%s/mass-per-county", dcsv))
write.csv( df,
        sprintf("%s/mass-per-county/zonal_volume_ENLOCALE.csv", dcsv),
        row.names = FALSE)
write.csv2(df,
        sprintf("%s/mass-per-county/zonal_volume_DELOCALE.csv", dcsv),
        row.names = FALSE)
