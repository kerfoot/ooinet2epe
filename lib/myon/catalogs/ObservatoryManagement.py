import myon.constants
import myon.http

# site_extension = getObservatorySiteExtension(observatory_id)
# Returns the site extension object (dictionary) for the Observatory specified
# by the observatory_id
def getObservatorySiteExtension(observatory_id):
    
    # Fetch the observatory site extension
    service = 'observatory_management'
    action = 'get_observatory_site_extension'
    params = {'site_id' : observatory_id}
    
    url = myon.http.createIonUrl(service, action, params)
    
    response = myon.http.getRequest(url)
    
    if 'GatewayError' in response['data']:
        exception = response['data']['GatewayError']['Exception']
        message = response['data']['GatewayError']['Message']
        raise exception(message)
    
    return response['data']['GatewayResponse']
    
# platform_sites = getObservatoryPlatformSites(observatory_id)
# Returns a list of PlatformSite resources (dictionaries) for all PlatformSites
# contained in the Observatory specified by observatory_id
def getObservatoryPlatformSites(observatory_id):
           
    site_extension = getObservatorySiteExtension(observatory_id)
    
    return site_extension['sites']
    
# deployments = getObservatoryDeployments(observatory_id)
# Returns a list of Deployment resources (dictionaries) for all Deployments
# contained in the Observatory specified by observatory_id
def getObservatoryDeployments(observatory_id):
    
    site_extension = getObservatorySiteExtension(observatory_id)
    
    return site_extension['deployments']
    
# data_products = getObservatoryDataProducts(observatory_id)
# Returns a list of DataProduct resources (dictionaries) for all DataProducts
# contained in the Observatory specified by observatory_id
def getObservatoryDataProducts(observatory_id):
    
    site_extension = getObservatorySiteExtension(observatory_id)
    
    return site_extension['data_products']
    
# observatories = groupObservatoriesBySpatialArea()
# Returns a dictionary mapping spatial_area_names to the group of Observatory
# resources they contain.  Each Observatory group is a dictionary mapping the
# Observatory name to the ion service gateway metadata response for that
# Observatory.
def groupObservatoriesBySpatialArea():
    
    observatories = {}
    
    # Fetch all Observatory resources
    obs_resources = myon.http.getResources("Observatory")
    
    SEEN_AREAS = []
    
    # Loop through each Observatory resource
    for obs, obs_id in obs_resources.items():
        
        response = myon.http.readResourceId(obs_id)
        
        if 'GatewayResponse' not in response['data']:
            print obs + ": Resource fetch failed!"
            continue
        
        meta = response['data']['GatewayResponse']
        
        if 'spatial_area_name' not in meta:
            print obs + ": Unknown spatial_area_name!"
            continue
        
        if meta['spatial_area_name'] not in SEEN_AREAS:
            observatories[meta['spatial_area_name']] = {}
            SEEN_AREAS.append(meta['spatial_area_name'])
        
        observatories[meta['spatial_area_name']][meta['local_name']] = meta
    
    return observatories
    