#######################################################################################################################
# Benthic Habitat Mapping Dive Survey Site Locations
# 
# Objective:  Create a shapefile for WCTSS SCUBA surveys of NCC & HG
#
# https://www.nceas.ucsb.edu/scicomp/usecases/AssignClosestPointsToPoints
#
# Author:     Sarah Davies
#             Sarah.Davies@dfo-mpo.gc.ca
#             250-756-7124
# Date:       December 4, 2017
######################################################################################################################

# start fresh
rm(list=ls())

# Set working directory
setwd("F:/GIS/SURVEY DATA/2019/DropCameraTideCorrections/Shapefiles")


################ Functions #####################################
################################################################

# Install missing packages and load required packages (if required)
UsePackages <- function( pkgs, update=FALSE, locn="http://cran.rstudio.com/" ) {
  # Identify missing (i.e., not yet installed) packages
  newPkgs <- pkgs[!(pkgs %in% installed.packages( )[, "Package"])]
  # Install missing packages if required
  if( length(newPkgs) )  install.packages( newPkgs, repos=locn )
  # Loop over all packages
  for( i in 1:length(pkgs) ) {
    # Load required packages using 'library'
    eval( parse(text=paste("library(", pkgs[i], ")", sep="")) )
  }  # End i loop over package names
  # Update packages if requested
  if( update ) update.packages( ask=FALSE )
}  # End UsePackages function

# Make packages available
UsePackages( pkgs=c("dplyr","maptools", "sf","rgdal","sp","geoR") ) 

# List all shp files
list.files(pattern = "\\.shp$")

# Read in shp
stns <- readOGR(".","Tide_stns")
drops <- readOGR(".","DropCam_sites")

plot(drops)
points(stns)

#  Define these vectors, used in the loop.
closestSiteVec <- vector(mode = "numeric",length = nrow(drops))
minDistVec     <- vector(mode = "numeric",length = nrow(drops))

# Get the vector index of the tide station closest to each drop camera deployment.
# Use the spDistsN1 function to compute the distance vector between each
# drop cam site and all of the tide stations. Then, find and
# retain the actual temperature, and the index of the closest temperature
# to each transect station.
#
# spDistsN1 usage: spDistsN1(pointList, pointToMatch, longlat)
#
# where:
#         pointList   : List of candidate points.
#         pointToMatch: Single point for which we seek the closest point in pointList.
#         longlat     : TRUE  computes Great Circle distance in km,
#                       FALSE computes Euclidean distance in units of input geographic coordinates
#
# We use Great Circle distance to increase distance calculation accuracy at high latitudes
# See the discussion of distance units in the header portion of this file
#
# minDistVec stores distance from the closest tide station to each density measurement point.
# closestSiteVec stores the index of the closest tide station to each density measurement point.

for (i in 1 : nrow(drops))
{
  # Distance vector bw each drop cam site & all of the tide stations
  distVec <- spDistsN1(stns,drops[i,],longlat = FALSE)
  minDistVec[i] <- min(distVec)
  closestSiteVec[i] <- which.min(distVec)
}

# Create the Tide Station Assignment table: merge the tide station point list with the drop cam point list
# into a five-column table.
#
Station <- as(stns[closestSiteVec,]$Sites,"character")
wTideStns= data.frame(coordinates(drops),drops$DropCamKey,
                        closestSiteVec,minDistVec,Station)
head(wTideStns)
str(wTideStns)

drops.df <- drops@data

drops_wTideStns <- merge(drops.df, wTideStns, by.x="DropCamKey", by.y="drops.DropCamKey")
drops_wTideStns <- dplyr::select(drops_wTideStns, -c("closestSiteVec","minDistVec"))

# Build shapefile
coordinates(drops_wTideStns) <- c("coords.x1", "coords.x2") 

# Coordinate reference system (http://spatialreference.org
crs.geo <- CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0") 

# define projection
proj4string(drops_wTideStns) <- crs.geo

# plot 
plot(drops_wTideStns)

filename <- "Drops_wTide_stns"
writeOGR(drops_wTideStns, dsn=".", layer=filename, driver="ESRI Shapefile", overwrite_layer = TRUE )




