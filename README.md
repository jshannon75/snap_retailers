# Historical database of SNAP authorized retailers
This repository stores data on SNAP authorized retailers nationally. Data are from the USDA's [SNAP retailer page](https://www.fns.usda.gov/snap/retailer-locator), which currently provides historical data through December 31, 2021. 

This project has added the following attributes to the USDA's data:
* Broader groupings of store types from USDA's classification for use in analysis
* Additional variables for years of authorization and the end of authorization in addition to the date
* Geographic identifiers for the county, tract, PUMA, and place of all listed retailers for use in aggregation and analysis.

There are two main files available for download, both in zipped format to meet Github's size restrictions:

* An [csv version of the data](https://github.com/jshannon75/snap_retailers/raw/master/data/hist_snap_retailer_final2021.zip) with separate files of retailer listings and variable descriptions
* A [geopackage version of the data](https://github.com/jshannon75/snap_retailers/raw/master/data/hist_snap_retailer_final2021_gpkg.zip) that can be used for spatial analysis in GIS or R/Python.

# History of this project

The previous version of this repository linked yearly records of SNAP retailers. USDA now provides a single historical file that includes retailer IDs, and so geocoding and updating these records is now much easier. The previous datasets are still available on this site, covering 2005-2020:

* The main CSV file [with this link](https://github.com/jshannon75/snap_retailers/raw/master/data/snap_retailers_usda.csv). This includes a combined version of the listings provided by USDA with dummy variables for each year and geographic coordinates for all stores.

* An additional file with the state, county, census tracts, and metropolitan statistical areas of each store [is avilable here](https://github.com/jshannon75/snap_retailers/raw/master/data/snap_retailers_crosswalk.csv) and can be joined with the store id code. Right click and choose "Save link as" to download. 

* Metadata showing variable names are available [on this spreadsheet](https://github.com/jshannon75/snap_retailers/raw/master/data/snap_retailers_metadata.csv). 

* The data folder of this repo contains the original files provided by USDA, which show store listings for June 30 from 2008-2019. 

* A research project specifically on dollar stores used [this CSV file](https://github.com/jshannon75/snap_retailers/raw/master/data/dollars_all.csv), also available in the data folder. This file includes all SNAP-authorized locations for Dollar General, Dollar Tree, and Family Dollar, along with geographic coordinates, years of operation, and geographic identifiers (county, state, metro area).

R scripts showing the data consolidation and editing process are also available in the home directory of the repo.

## Version history/notes

* 5/5/2022: A new version of the dataset using USDA's historical retailer data was created and added to the repository
* 11/17/2020: Data for January and June 2020 were added to the dataset
* 10/28/2019: 2019 Retailers were added to the dataset. These are stores authorized on June 30, 2019. Most were matched to existing records using exact or fuzzy matching. See the 2019 update script for the exact procedure.
* 10/27/2019: An additional ~10,000 retailers were combined based on fuzzy matching on address. 
* 10/19/2019: About 15,000 duplicate retailers were identified and removed. See the "duplicate_reduction" script for that date for more detail.
* 12/18/2018: A small correction was made for the MSA id on some stores (< 5,000). 
* 12/14/2018: Data on dollar stores nationally was added to the data folder, and a script for visualizing these across years is now in the scripts folder.
* 12/12/2018: Data on SNAP retailers from June 30, 2018 was joined to the existing dataset. Location IDs were also added for unique addresses, and some duplicates in the earlier dataset were combined.
