#######################################################################################################################
# Benthic Habitat Mapping Dive Survey Site Locations
# 
# Objective:  Create a shapefile for WCTSS SCUBA surveys of NCC & HG
#
# Requires:   Run 1.ExtractDataFromMSAccess.R script
#
# Author:     Sarah Davies
#             Sarah.Davies@dfo-mpo.gc.ca
#             250-756-7124
# Date:       December 4, 2017
######################################################################################################################

# start fresh
rm(list=ls())

# Check which version of R is being used and reset if necessary
Sys.getenv("R_ARCH")   
# The message returned will tell you which version of R is being used
# "/i386" 32 bit R --- which is necessary to grab data from MS Access database
# "/64"   64 bit R
# To reset: Select Tools menu | Global Options... | R Version: | Change
# Then you will have to open and close R for the changes to take effect

# Set working directory
setwd("F:/GIS/SURVEY DATA/2019/DropCameraTideCorrections")


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

# Remove rows with NA values in specific columns within a dataframe
completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}

# Make packages available
UsePackages( pkgs=c("dplyr","reshape", "vegan", "stringr","rgdal","sp","geoR") ) 

##############################
# 1. Read in the WCTSS data
##############################
# Read in tables that were extracted from the MS Access db using the script ExtractDataFromMSAccess.R
hdrs <- read.csv("./Data/ExtractedData/Headers.csv", header=T, sep=",")
# Subset headers data
sites <- dplyr::select(hdrs, HKey, Survey, Year, Month, Day, LatDegStart, LatMinStart, LonDegStart, LonMinStart)

# Calculate lat & lon
sites$lon <- ( (sites$LonDegStart) + (sites$LonMinStart/60) )
sites$lon <- ( sites$lon*-1 )
sites$lat <- ( (sites$LatDegStart) + (sites$LatMinStart/60) )

# Build shapefile
sites <- completeFun( sites, c("lon", "lat") )
coordinates(sites) <- c("lon", "lat")

# Coordinate reference system (http://spatialreference.org
# WGS 1984
crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ") 

# define projection
proj4string(sites) <- crs.geo

# plot and reproject
plot(sites)
# BC Albers NAD 83
proj <- "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0"
projdefs <- "+datum=NAD83 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
geoCRS <- paste( proj, projdefs, sep=" " )
sites_albers <- spTransform(sites, geoCRS)
plot(sites_albers)

filename <- "SCUBA_sites"
writeOGR(sites_albers, dsn="./Shapefiles", layer=filename, driver="ESRI Shapefile", overwrite_layer = TRUE )




