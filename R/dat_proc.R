library(tidyverse)
library(raster)
library(rgdal)

source('R/funcs.R')

######
# qser locations

qser_pts <- readOGR(dsn = 'M:/GIS/EFDC', layer = 'qser_pts')
save(qser_pts, file = 'data/qser_pts.RData', compress = 'xz')

######
# Locations of field observations

field_pts <- readOGR(dsn = 'M:/GIS/EFDC', layer = 'field_pts')
save(field_pts, file = 'data/field_pts.RData', compress = 'xz')

######
# estimate average depth in each ij grid cell for EFDC grid

# # bathymetry raster, created manually in arcgis
# rst <- raster('M:/GIS/EFDC/pb_gom_full')
# 
# # shapefile exported from cvl grid
# grd <- readOGR(dsn="M:/GIS/EFDC", layer="pb_grid_new")
# 
# # extract depths for each efdc grid cell from the depth raster
# deps <- extract(rst, grd, fun = mean, na.rm = TRUE)
# 
# # add the depths to spatial polygons data frame
# grd@data <- mutate(data.frame(grd),
#   depth = deps[,1]
# )
# 
# # save
# pb_grid <- grd
# save(pb_grid, file = 'data/pb_grid.RData', compress = 'xz')

data(pb_grid)

# format depth data from shapefile
pb_grid <- pb_grid@data %>% 
  dplyr::select(I, J, depth) %>% 
  mutate(
    I = 2 + I, # I is shifted in shapeifle
    I = as.character(I),
    J = 2 + J, # J is shifted in shapefile
    J = as.character(J), 
    depth = pmax(0.5, depth), 
    depth = as.character(depth)
  )

# import dxdy file with no depth data
dxdy <- readLines('EFDC/dxdy.inp')

# format for merge
dxdyhd <- dxdy[1:4]
dxdy <- dxdy[-c(1:4)] %>% 
  strsplit(., '\\s+') %>% 
  do.call('rbind', .) %>% 
  data.frame(stringsAsFactors = F) %>% 
  rename(
    I = X2, 
    J = X3
  ) 

# arrange depths in pb_grid by i, j values in dxdy
deps <- dplyr::select(dxdy, I, J) %>% 
  left_join(., pb_grid, by = c('I', 'J'))

# fill depths in dxdy with the values in deps, correct order
# first column is depth, second is bottom depth (negative)
dxdy$X6 <- deps$depth
dxdy$X7 <- paste0('-', deps$depth)

# add extra column for veg type
dxdy$X9 <- rep(0, nrow(dxdy))

# format dxdy for writelines
dxdy <- apply(dxdy, 1, paste, collapse = '  ')
dxdy <- c(dxdyhd, dxdy)

# save
writeLines(dxdy, 'EFDC/dxdy.inp')

######
# setup TEMP.INP, SALT.INP, DYE.INP

getinp(dxdyin = 'EFDC/dxdy.inp', sig = 5, val = 14, outfl = 'EFDC/TEMP.INP', 
  frstrow = 'C       TEMP.INP      PENSACOLA BAY, C')

getinp(dxdyin = 'EFDC/dxdy.inp', sig = 5, val = 23, outfl = 'EFDC/SALT.INP', 
  frstrow = 'C       SALT.INP      PENSACOLA BAY, PPT')

getinp(dxdyin = 'EFDC/dxdy.inp', sig = 5, val = 0, outfl = 'EFDC/DYE.INP', 
  frstrow = 'C       DYE.INP      PENSACOLA BAY, PPT')

######
# get tidal level data from NOAA station at PB downtown
# https://tidesandcurrents.noaa.gov/waterlevels.html?id=8729840

# only one year can be downloaded per request
yrs <- seq(2002, 2009)
url <- 'https://tidesandcurrents.noaa.gov/api/datagetter?product=hourly_height&application=NOS.COOPS.TAC.WL&begin_date=20020101&end_date=20021231&datum=MLLW&station=8729840&time_zone=LST&units=metric&format=CSV'

# download each year by changing dates in url
noaa_sel <- purrr::map(yrs, function(x){
  
  strdt <- paste0(x, '0101')
  enddt <- paste0(x, '1231')
  
  urlin <- gsub('(&begin_date=)[0-9]+(&)', paste0('\\1', strdt, '\\2'), url)
  urlin <- gsub('(&end_date=)[0-9]+(&)', paste0('\\1', enddt, '\\2'), urlin)
  
  tmp <- read.csv(urlin)
  
  return(tmp)

  }) %>% 
  do.call('rbind', .) %>% 
  mutate(
    datetime = as.character(Date.Time), 
    datetime = as.POSIXct(datetime, tz = 'America/Regina'), 
    wlevel_m = Water.Level
  ) %>% 
  dplyr::select(datetime, wlevel_m)
  
save(noaa_sel, file = 'data/noaa_sel.RData', compress = 'xz')
