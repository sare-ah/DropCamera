#######################################################################################################################
# Substrate Modelling 
# 
# Objective:  Build Drop Cam validation data for substrate modelling
#
# Background: Drop camera was deployed at SCUBA sites at three target depths (90,120,150 meters)
#
# 
# Author:     Sarah Davies
#             Sarah.Davies@dfo-mpo.gc.ca
#             250-756-7124
# Date:       May 7, 2019
######################################################################################################################

# start fresh
rm(list=ls())

# Set working directory
setwd("T:/Substrate/DropCam_data")

require(dplyr)
require(sp)
require(rgdal)
require(geoR)

### Functions ###  
# Remove rows with NA values in specific columns within a dataframe
completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}

# Read in drop camera data
myFile <- "T:/DropCamera/AnnotationIn2019/8-DropCam_KS.csv"
dropCam  <- read.csv(myFile,header=TRUE, sep=",", strip.white=T, stringsAsFactors = FALSE) 

# Set records with missing data to NA
dropCam[dropCam == "."] <- NA
dropCam[dropCam == ""] <- NA
str(dropCam)

# Calculate lat & lon
dropCam$Lon <- as.numeric( (dropCam$LongDeg) + (dropCam$LongMin/60) )
dropCam$Lon <- ( dropCam$Lon*-1 )
dropCam$Lat <- as.numeric( (dropCam$LatDeg) + (dropCam$LatMin/60) )

# Test for complete cases in specific fields
goodDrops <- completeFun( dropCam, c("Year","Month","Day","TimeIn","Lat","Lon","ActualDepth","Substrate1") )

# Read in substrate category table
sub.cat <- read.csv( "SubstrateCategories.csv", header=T, sep=",", colClasses = c("integer","character","integer",rep("character",4)))

# Match substrateID to substrate category
goodDrops <- dplyr::left_join(goodDrops, sub.cat, by=c("Substrate1", "Substrate2"))
summary(goodDrops)

# Subset drop camera data
goodDrops <- dplyr::select(goodDrops,DropCamKey,Survey,Transect,Lat,Lon,RMSM.cat,RMSM.Nme,Substrate1,Substrate2)

# Build shapefile
goodDrops <- completeFun( goodDrops, c("Lon", "Lat") )
coordinates(goodDrops) <- c("Lon", "Lat")

# Coordinate reference system (http://spatialreference.org
# WGS 1984
crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ") 

# define projection
proj4string(goodDrops) <- crs.geo

# plot and reproject
plot(goodDrops)
# BC Albers NAD 83
proj <- "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0"
projdefs <- "+datum=NAD83 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
geoCRS <- paste( proj, projdefs, sep=" " )
goodDrops_albers <- spTransform(goodDrops, geoCRS)
plot(goodDrops_albers)

filename <- "DropCam_sites4SubstrateModel"
writeOGR(goodDrops_albers, dsn="./Shapefiles", layer=filename, driver="ESRI Shapefile", overwrite_layer = TRUE )
cat("Fini!")





