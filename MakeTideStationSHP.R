################################################
# Make tide station shapefile
# 
# Tide station locations taken from:
# https://tides.gc.ca/eng/station/list
#
# Author:     Sarah Davies
#             Sarah.Davies@dfo-mpo.gc.ca
#             250-756-7124
# Date:       May 9, 2019
################################################

# start fresh
rm(list=ls())

# Set working directory
setwd("F:/GIS/SURVEY DATA/2019/DropCameraTideCorrections")

# Install missing packages and load required packages (if required)
if(!require(dplyr)) install.packages("dplyr")
if(!require(rgdal)) install.packages("rgdal")

# Remove rows with NA values in specific columns within a dataframe
completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}

# Read in data
myFile <- file.choose() # "F:\GIS\SURVEY DATA\2019\DropCameraTideCorrections\ListOfTideStations.csv"
stns <- read.csv(myFile, header=T, sep=",",stringsAsFactors = F)

# Build shapefile
stns <- completeFun( stns, c("Longitude", "Latitude") )
coordinates(stns) <- c("Longitude", "Latitude")

# Coordinate reference system (http://spatialreference.org
# BC Albers NAD 83
proj <- "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0"
projdefs <- "+datum=NAD83 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
geoCRS <- paste( proj, projdefs, sep=" " )

# define projection
proj4string(stns) <- geoCRS 

# plot and reproject
plot(stns)

filename <- "Tide_stns"
writeOGR(stns, dsn=".", layer=filename, driver="ESRI Shapefile", overwrite_layer = TRUE )




