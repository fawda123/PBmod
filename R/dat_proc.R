
library(tidyverse)
library(raster)
library(rgdal)

######
# estimate average depth in each ij grid cel for EFDC grid

# bathymetry raster, created manually in arcgis
rst <- raster('M:/GIS/EFDC/pb_gom_full')

# shapefile exported from cvl grid
grd <- readOGR(dsn="M:/GIS/EFDC", layer="pb_grid_new")

# extract depths for each efdc grid cell from the depth raster
deps <- extract(rst, grd, fun = mean, na.rm = TRUE)

# add the depths to spatial polygons data frame
grd@data <- mutate(data.frame(grd),
  depth = deps[,1]
)

pb_grid <- grd
save(pb_grid, file = 'data/pb_grid.RData', compress = 'xz')
