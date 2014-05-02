import urllib
import json
import os
import sys
import re

# Root directory to write the downloaded NetCDF files
NC_ROOT = '/Users/kerfoot/datasets/OOI/ion/dataProducts/erddap-nc'
if not os.path.exists(NC_ROOT):
    print 'Invalid NetCDF destination:',NC_ROOT
    sys.exit(1)
    
# Location of the OOI resource JSON files
PRODUCTS_DIR = '/Users/kerfoot/datasets/OOI/ion/resources'
if not os.path.exists(PRODUCTS_DIR):
    print 'Invalid DataProducts location:',PRODUCTS_DIR
    sys.exit(1)
 
# Taraget Observatory resource JSON file   
DATA_PRODUCTS_FILE = 'GP05MOAS_dataProducts.cluster.json'
jsonFile = os.path.join(PRODUCTS_DIR, DATA_PRODUCTS_FILE)
if not os.path.exists(jsonFile):
    print 'Invalid file:',jsonFile
    sys.exit(1)

# Load the JSON file as a python data structure    
obs = json.load(open(jsonFile))
if not obs['reference_designator']:
    print obs['name'] + ': No Observatory reference designator'
    sys.exit(1)

# Set (and create if it doesn't exist) the Observatory NetCDF destination   
NC_DEST = os.path.join(NC_ROOT, obs['reference_designator'], 'nc3')
if not os.path.exists(NC_DEST):
    print 'Creating NetCDF destination:',NC_DEST
    os.makedirs(NC_DEST)

# Loop through each of the platforms of this Observatory and download all available DataProducts    
for platform in obs['children']:
    
    # Loop through all DataProducts
    for dataProduct in platform['children']:
            
        # Create the ERDDAP url to the NetCDF file
        erddapNcUrl = dataProduct['erddap_url'].replace('.html', '.nc')
        
        # Use the OOI product identifier (ie: TEMPWAT, PRACSAL, etc.), if 
        # available, or the 'name', if not available for creating the NetCDF 
        # destination file name
        match = re.search('^[A-Z]+', dataProduct['name'])
        if match:
            productName = match.group()
        else:
            productName = dataProduct['name']
        
        if dataProduct['product_download_size_estimated'] == 0:
            print productName, 'DataProduct file is empty'
            continue
            
        # Destination NetCDF file name
        localNc = '-'.join((platform['reference_designator'], productName, dataProduct['_id'])) + '.nc'
        
        # Fullpath to the destination NetCDF filename
        destNc = os.path.join(NC_DEST, localNc)
        
        print 'Fetching ERDDAP NetCDF:',productName
        #print 'Destination File:',destNc
        
        # Fetch the url
        (remoteUrl, headers) = urllib.urlretrieve(erddapNcUrl, destNc)
        
        # If the dataset is not available, headers.type === 'text/html', so delete the file
        if re.search('^text/html$', headers.type):
            print 'ERDDAP NetCDF not available:', erddapNcUrl
            os.remove(destNc)
            