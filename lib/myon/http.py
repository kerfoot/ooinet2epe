import myon.constants
import urllib2
import json

# Url pieces
#ION_A_URL = 'http://sg.a.oceanobservatories.org:5000/ion-service'
#ION_B_URL = 'http://sg.b.oceanobservatories.org:5000/ion-service'
#ION_URL = ION_B_URL

# url = createIonUrl(service,action,params)
#
# Creates a properly formatted ION Service Gateway url for the specified 
# service, action and query variables
def createIonUrl(service='list_resource_types', action='', params={}):
    
    # Join the url pieces into a url
    URL = '/'.join([ION_URL, service, action])
    
    # If PARAMS has items(), first join the key and the value with '=', then join
    # each of these items with '&'.  Finally, append '?' and the result to form the
    # full query
    if params:
        QUERY = '&'.join(['='.join([key, value]) for key, value in params.items()])
        URL += '?' + QUERY
    
    return URL
    
# obj = getRequest(url)
#
# Attempt to retrieve the requested url and convert the JSON response to a 
# python data structure.
def getRequest(url):
    
    # Fetch the URL
    try:
        # Open the url
        request = urllib2.urlopen(url)
        # Convert the json string response to a python list
        obj = json.loads(request.read())
    except urllib2.URLError as e:
        print 'Request Failed: {:s} ({:d})'.format(e.reason[1], e.reason[0])
    
    return obj
    
# obj = getResources(restype)
#
# Retrieve all resources for the specified resource type registered in the
# ION Resource Registry.  On success, the return value is a dictionary mapping
# resource name to the resource id.
def getResources(restype):
    
    # Define the service, action and input args
    service = 'resource_registry'
    action = 'find_resources_ext'
    params = {'restype' : restype,
        'id_only' : 'True'}
        
    # Create the url
    url = createIonUrl(service, action, params)
    
    print "myon.http.getResources URL: ", url
    
    # Retrieve json and convert to a python data structure
    response = getRequest(url)
    
    if 'GatewayError' in response['data']:
        # Request failed
        obj = {}
    else:
        # Store only the second element of the GatewayResponse
        obj = dict((i['name'],i['id']) for i in response['data']['GatewayResponse'][1])
    
    return obj
    
# obj = readResourceId(resource_id)
# 
# General purpose routine to retrieve metadata for the resource identified by 
# resource id.
def readResourceId(resource_id):
    
    service = 'resource_registry'
    action = 'read'
    params = {'object_id' : resource_id}
    
    url = createIonUrl(service, action, params)
    
    #print "myon.http.readResource URL: ", url
    
    obj = getRequest(url)
    
    return obj
    