import myon.http
import myon.geo
import myon.cluster.PlatformSite
from operator import itemgetter

def getObservatories():
    
    # Set up the top-level cluster
    observatories = {'name' : 'OOI Observatories',
        'children' : []}
    
    # Fetch all Observatory resources as a dictionary mapping Observatory name
    # to resource id
    resources = myon.http.getResources('Observatory')
    
    if not resources:
        return observatories
    
    spatial_areas = {}
    
    # Loop through each item in resources
    for observatory, observatory_id in resources.items():
        
        # Fetch the metadata for the observatory
        response = myon.http.readResourceId(observatory_id)
        
        if 'GatewayResponse' not in response['data']:
            continue
        
        obs_data = response['data']['GatewayResponse']
        
        if obs_data['spatial_area_name'] not in spatial_areas:
            cluster = {'name' : obs_data['spatial_area_name'],
                'children' : []}
            spatial_areas[obs_data['spatial_area_name']] = cluster
            
        name = obs_data['name'].replace(obs_data['spatial_area_name'], '').strip()
        if not name:
            name = obs_data['name']
            
        child = {'name' : name,
            'full_name' : obs_data['name'],
            'resource_id' : obs_data['_id'],
            'available' : True if obs_data['availability'] == 'AVAILABLE' else False,
            'deployed' : True if obs_data['lcstate'] == 'DEPLOYED' else False,
            'ts_created' : obs_data['ts_created'],
            'ts_updates' : obs_data['ts_updated'],
            'restype' : obs_data['type_'],
            'geometry' : myon.geo.resource2geoJson(obs_data),
            'description' : obs_data['description'],
            'children' : []}
        
        spatial_areas[obs_data['spatial_area_name']]['children'].append(child)
        
    for spatial_area in sorted(spatial_areas.keys()):
        spatial_areas[spatial_area]['children'] = sorted(spatial_areas[spatial_area]['children'], key=itemgetter('name'))
        observatories['children'].append(spatial_areas[spatial_area])
        
    return observatories   
    
def getObservatoryPlatformSites(observatory_id):
    
    # Fetch the observatory data products
    service = 'observatory_management'
    action = 'find_site_data_products'
    params = {'parent_resource_id' : observatory_id}
    
    url = myon.http.createIonUrl(service, action, params)
    
    #print "Fetching Observatory PlatformSites: ", url
    
    response = myon.http.getRequest(url)
    
    if 'GatewayError' in response['data']:
        exception = response['data']['GatewayError']['Exception']
        message = response['data']['GatewayError']['Message']
        raise exception(message)
        
    platform_sites = []
    
    # Loop through each resource
    for resource_id in response['data']['GatewayResponse']['site_children'].keys():
        
        platform = myon.cluster.PlatformSite.getPlatformSite(resource_id)
        
        if not platform:
            continue
            
        platform_sites.append(platform)
        
    platform_sites = sorted(platform_sites, key=itemgetter('name'))
    
    return platform_sites    
    
def getObservatoryDataProducts(observatory_id):
    
    product_groups = {}
    
    response = myon.http.readResourceId(observatory_id)
    if 'GatewayResponse' not in response['data']:
        return product_groups
    elif response['data']['GatewayResponse']['type_'] != 'Observatory':
        return product_groups
    
    platforms = myon.cluster.Observatory.getObservatoryPlatformSites(observatory_id)

    product_groups = myon.cluster.PlatformSite.groupPlatformSitesDataProducts(platforms)

    return product_groups
                
            