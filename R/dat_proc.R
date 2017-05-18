library(tidyverse)
library(raster)
library(rgdal)

source('R/funcs.R')

######
# qser locations

qser_pts <- readOGR(dsn = 'M:/GIS/EFDC', layer = 'qser_pts')
save(qser_pts, file = 'data/qser_pts.RData', compress = 'xz')

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

# format dxdy for writelines
dxdy <- apply(dxdy, 1, paste, collapse = '  ')
dxdy <- c(dxdyhd, dxdy)

# # save
# writeLines(dxdy, 'EFDC/dxdy.inp')

######
# setup TEMP.INP, SALT.INP, DYE.INP

getinp(dxdyin = 'EFDC/dxdy.inp', sig = 5, val = 14, outfl = 'EFDC/TEMP.INP', 
  frstrow = 'C       TEMP.INP      PENSACOLA BAY, C')

getinp(dxdyin = 'EFDC/dxdy.inp', sig = 5, val = 23, outfl = 'EFDC/SALT.INP', 
  frstrow = 'C       SALT.INP      PENSACOLA BAY, PPT')

getinp(dxdyin = 'EFDC/dxdy.inp', sig = 5, val = 0, outfl = 'EFDC/DYE.INP', 
  frstrow = 'C       DYE.INP      PENSACOLA BAY, PPT')

