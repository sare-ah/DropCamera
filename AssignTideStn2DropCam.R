#######################################################################################################################
# Assign tide stations to drop camera deployments
#
# Code adapted from example found here:
# https://www.nceas.ucsb.edu/scicomp/usecases/AssignClosestPointsToPoints
#
# Author:     Sarah Davies
#             Sarah.Davies@dfo-mpo.gc.ca
#             250-756-7124
# Date:       May 9, 2019
######################################################################################################################

# start fresh
rm(list=ls())

# Set working directory
setwd("F:/GIS/SURVEY DATA/2019/DropCameraTideCorrections/Shapefiles")

# Install missing packages and load required packages (if required)
if(!require(dplyr)) install.packages("dplyr")
if(!require(maptools)) install.packages("maptools")
if(!require(sf)) install.packages("sf")
if(!require(rgdal)) install.packages("rgdal")

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

# Create the Tide Station assignment table
Station <- as(stns[closestSiteVec,]$Sites,"character")
wTideStns= data.frame(coordinates(drops),drops$DropCamKey,
                        closestSiteVec,minDistVec,Station)
head(wTideStns)
str(wTideStns)

# Build a new attribute table the clunky way...
drops.df <- drops@data
drops_wTideStns <- merge(drops.df, wTideStns, by.x="DropCamKey", by.y="drops.DropCamKey")
drops_wTideStns <- dplyr::select(drops_wTideStns, -c("closestSiteVec","minDistVec"))

# Build shapefile
coordinates(drops_wTideStns) <- c("coords.x1", "coords.x2") 

# Coordinate reference system (http://spatialreference.org
# BC Albers NAD 83
proj <- "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0"
projdefs <- "+datum=NAD83 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
geoCRS <- paste( proj, projdefs, sep=" " )

# define projection
proj4string(drops_wTideStns) <- geoCRS 

# plot 
plot(drops_wTideStns)

# Save as shp
filename <- "Drops_wTide_stns"
writeOGR(drops_wTideStns, dsn=".", layer=filename, driver="ESRI Shapefile", overwrite_layer = TRUE )




