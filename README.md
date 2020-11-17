# National database of SNAP authorized retailers, 2008-2020
This repository stores data on SNAP authorized retailers nationally from 2008-2020. Data are from the USDA, with records linked across years and all stores geocoded. 

A research rationale for these data, details on its construction, and a short descriptive analysis are [available here](https://jshannon75.github.io/snap_retailers/overview_paper).

An interactive dashboard allowing users to explore this dataset in the 45 largest metropolitan areas is available [as a web application](https://comapuga.shinyapps.io/snapretailexplorer/).

Multiple files are available on this site:

* The main CSV file [with this link](https://github.com/jshannon75/snap_retailers/raw/master/data/snap_retailers_usda.csv). This includes a combined version of the listings provided by USDA with dummy variables for each year and geographic coordinates for all stores.

* An additional file with the state, county, census tracts, and metropolitan statistical areas of each store [is avilable here](https://github.com/jshannon75/snap_retailers/raw/master/data/snap_retailers_crosswalk.csv) and can be joined with the store id code. Right click and choose "Save link as" to download. 

* Metadata showing variable names are available [on this spreadsheet](https://github.com/jshannon75/snap_retailers/raw/master/data/snap_retailers_metadata.csv). 

* The data folder of this repo contains the original files provided by USDA, which show store listings for June 30 from 2008-2019. 

* A research project specifically on dollar stores used [this CSV file](https://github.com/jshannon75/snap_retailers/raw/master/data/dollars_all.csv), also available in the data folder. This file includes all SNAP-authorized locations for Dollar General, Dollar Tree, and Family Dollar, along with geographic coordinates, years of operation, and geographic identifiers (county, state, metro area).

R scripts showing the data consolidation and editing process are also available in the home directory of the repo.

## Version history/notes

* 11/17/2020: Data for January and June 2020 were added to the dataset
* 10/28/2019: 2019 Retailers were added to the dataset. These are stores authorized on June 30, 2019. Most were matched to existing records using exact or fuzzy matching. See the 2019 update script for the exact procedure.
* 10/27/2019: An additional ~10,000 retailers were combined based on fuzzy matching on address. 
* 10/19/2019: About 15,000 duplicate retailers were identified and removed. See the "duplicate_reduction" script for that date for more detail.
* 12/18/2018: A small correction was made for the MSA id on some stores (< 5,000). 
* 12/14/2018: Data on dollar stores nationally was added to the data folder, and a script for visualizing these across years is now in the scripts folder.
* 12/12/2018: Data on SNAP retailers from June 30, 2018 was joined to the existing dataset. Location IDs were also added for unique addresses, and some duplicates in the earlier dataset were combined.
