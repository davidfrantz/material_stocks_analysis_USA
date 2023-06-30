require(dplyr)
require(tidyr)
require(plotly)

dir_csv <- "csv/mass-per-state"
files_csv <- dir(dir_csv, "ENLOCALE", full.names = TRUE)
n_csv <- length(files_csv)

df_ <- numeric(0)

for (i in 1:n_csv){
  
  tmp <- read.csv(files_csv[i]) %>%
    filter(!category %in% c("building", "other", "street", "rail", "grand_total_t_10m2")) %>% 
    mutate(category = gsub("_.*", "", category)) %>%
    mutate(category = gsub("other", "mobility", category)) %>%  
    mutate(category = gsub("street", "mobility", category)) %>%
    mutate(category = gsub("rail", "mobility", category)) %>%
    group_by(category) %>%
    summarize_all("sum")
  
  df_ <- rbind(df_, tmp)
  
}

df_ <- df_ %>% 
  group_by(category) %>%
  summarize_all("sum") %>%
  select(-total)

df_ <- df_ %>% rbind(0)
df_$category[3] <- "biomass"
df_$other_biomass_based_materials[3] <- 4.85e10
df_ <- df_ %>% mutate_if(is.numeric, '*', 1000)


names(df_) <- gsub("aluminum"                              , "01 01 aluminum"                , names(df_))             
names(df_) <- gsub("copper"                                , "01 02 copper"                  , names(df_))             
names(df_) <- gsub("iron_steel"                            , "01 03 iron + steel"            , names(df_))              
names(df_) <- gsub("all_other_metals"                      , "01 04 other metals"            , names(df_))         
names(df_) <- gsub("concrete"                              , "02 01 concrete"                , names(df_))            
names(df_) <- gsub("bricks"                                , "02 02 bricks"                  , names(df_))             
names(df_) <- gsub("glass"                                 , "02 03 glass"                   , names(df_))            
names(df_) <- gsub("aggregate"                             , "02 04 aggregate"               , names(df_))
names(df_) <- gsub("all_other_minerals"                    , "02 05 other minerals"          , names(df_))        
names(df_) <- gsub("timber"                                , "03 01 timber"                  , names(df_))
names(df_) <- gsub("other_biomass_based_materials"         , "03 02 other biomass"           , names(df_))
names(df_) <- gsub("bitumen"                               , "04 01 bitumen"                 , names(df_))            
names(df_) <- gsub("all_other_fossil_fuel_based_materials" , "04 02 other petroleum products", names(df_))
names(df_) <- gsub("insulation"                            , "05 01 insulation"              , names(df_))             
names(df_) <- gsub("all_other_materials"                   , "05 02 all other materials"     , names(df_))                  


material_groups <- c(
  "metals",
  "minerals",
  "biomass",
  "petroleum",
  "other"
)



df_ <- df_[,order(colnames(df_), decreasing = TRUE)]
df_ <- df_ %>% 
  select(-category) %>% 
  #mutate_all(`/`(1e12)) %>% 
  as.matrix(row.names = df_$category) / 1e12


{
  tiff("plot/barchart_materials/barchart_materials.tif",
       width = 6.5, height = 5.0, units = "cm", pointsize = 7,
       compression = "lzw", res = 600, type = "cairo", antialias = "subpixel"
  )
  
  par(
    mai = c(0.4, 0.8, 0.1, 0.1),
    cex = 1,
    las = 1
  )
  

  
  cols <- c(
    rgb(255/255, 103/255, 110/255, 1), 
    rgb(68/255, 97/255, 134/255, 1), 
    rgb(127/255, 127/255, 127/255, 1)
  )
  

  barplot(
    df_,
    horiz = TRUE, 
    col= cols,
    names.arg = gsub("^[0-9]{2} [0-9]{2} ", "", colnames(df_)),
    cex.names = 0.8,
    xlim = c(0, 70),
    las = 1,
    border = NA
  )
  

  
  box(bty = "l")
  
  
  dev.off()
}




