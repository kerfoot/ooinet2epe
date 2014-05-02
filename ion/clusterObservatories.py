import myon.constants
import myon.cluster.Observatory
import json
import os.path

JSON_DIR = '/Users/kerfoot/datasets/OOI/ion/resources'

myon.http.ION_URL = myon.constants.ION_B_URL

obs = myon.cluster.Observatory.getObservatories()

if obs:
    jsonFile = os.path.join(JSON_DIR, 'observatories.cluster.json')
    
    try:
        print 'Writing JSON: ', jsonFile
        fid = open(jsonFile, 'w')
        fid.write(json.dumps(obs))
        fid.close()
    except IOError as e:
        print e        
    