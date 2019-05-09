# Scripts for working with drop camera data

*** AssignTideStn2DropCam.R ***
- Reads two shapefiles (tide stations and drop camera sites)
- Determines the closest tide station to each drop camera deployment
- Outputs a new shapefile with the drop camera sites, its attributes, and closest tide station


*** MakeTideStationsSHP.R ***
- Read in drop camera csv with lat, lon
- Create shapefile

*** BuildDropCameraValidationData.R ***
- Read in drop camera csv and substrate crosswalk table
- Create new fields for Rock,Mixed,Sand,Mud substrate classification and for BoP BType
