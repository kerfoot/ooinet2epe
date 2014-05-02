import myon.constants
import myon.cluster.Observatory
import os
import json

JSON_DIR = '/Users/kerfoot/datasets/OOI/ion/resources'

# Set the ion url
myon.http.ION_URL = myon.constants.ION_B_URL

# Get the list of Observatory resources
obs = myon.http.getResources('Observatory')

# Loop through each observatory and get the list of DataProducts
for (observatory, resourceId) in obs.items():
    
    obsDataProducts = myon.cluster.Observatory.getObservatoryDataProducts(resourceId)
    
    if not obsDataProducts['reference_designator']:
        continue
        
    jsonFile = os.path.join(JSON_DIR, obsDataProducts['reference_designator'] + '_dataProducts.cluster.json')
    
    print 'Writing JSON: ', jsonFile
    
    fid = open(jsonFile, 'w')
    
    fid.write(json.dumps(obsDataProducts))
    
    fid.close
    