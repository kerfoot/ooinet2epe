import myon.http
import myon.geo
import re
from operator import itemgetter

def getObservatories():
    
    # Set up the top-level cluster
    observatories = {'name' : 'OOI Spatial Areas',
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
        response = myon.http.readResource(observatory_id)
        
        if 'GatewayResponse' not in response['data']:
            continue
        
        obsData = response['data']['GatewayResponse']
        
        if obsData['spatial_area_name'] not in spatial_areas:
            cluster = {'name' : obsData['spatial_area_name'],
                'children' : []}
            spatial_areas[obsData['spatial_area_name']] = cluster
        
        # Create a geoJson object containing the geospatial coordinates of the observatory
        obsData['geometry'] = myon.geo.resource2geoJson(obsData)
        # Add 'children'
        obsData['children'] = []
        spatial_areas[obsData['spatial_area_name']]['children'].append(obsData)
        
    for spatial_area in sorted(spatial_areas.keys()):
        spatial_areas[spatial_area]['children'] = sorted(spatial_areas[spatial_area]['children'], key=itemgetter('name'))
        observatories['children'].append(spatial_areas[spatial_area])
        
    return observatories   
    
def getObservatoryDataProducts(resourceId):
    
    dataProducts = {}
     
    #response = myon.http.readResource(resourceId)
    #    
    #if 'GatewayResponse' not in response['data']:
    #    return dataProducts
    
    obsExt = myon.http.getObservatoryExt(resourceId)
    if not obsExt:
        return dataProducts
        
    dataProducts = {'_id' : obsExt['_id'],
        'children' : [],
        'name' : obsExt['resource']['name'],
        'reference_designator' : obsExt['resource']['reference_designator'],
        'type_' : obsExt['resource']['type_'],
        'ion_url' : obsExt['ion_url'],
        }
        
    for platform in obsExt['platform_station_sites']:
        
        platformExt = myon.http.getPlatformSiteExt(platform['_id'])
        if not platformExt:
            continue
            
        pGroup = {'_id' : platformExt['resource']['_id'],
            'children' : [],
            'deployments' : platformExt['deployments'],
            'name' : platformExt['resource']['local_name'],
            'reference_designator' : platformExt['resource']['reference_designator'],
            'type_' : platformExt['resource']['type_'],
            'ion_url' : platformExt['ion_url'],
            }
            
        platformDataProducts = getPlatformSiteDataProducts(platformExt['resource']['_id'])
        
        if not platformDataProducts:
            continue
        
        pGroup['children'] = platformDataProducts
    
        dataProducts['children'].append(pGroup)
    
    return dataProducts
    
def getPlatformSiteDataProducts(resourceId):
    
    dataProducts = []
    
    platformSiteExt = myon.http.getPlatformSiteExt(resourceId)
    
    if not platformSiteExt:
        print "Error"
        return dataProducts
    
    print 'PlatformSite: ', platformSiteExt['resource']['name']
    
    for dataProduct in platformSiteExt['data_products']:
        
        dpExt = myon.http.getDataProductExt(dataProduct['_id'])
        if not dpExt:
            continue
        
        print 'DataProduct: ', dpExt['resource']['name']
        
        dataProduct['ion_name'] = unicode(dataProduct['name'])
        dataProduct['erddap_url'] = unicode(dpExt['computed']['data_url']['value'])
        dataProduct['ion_url'] = dpExt['ion_url']
        
        if dpExt['resource']['ooi_short_name']:
            dataProduct['name'] = dpExt['resource']['ooi_short_name'] + ' ' + dpExt['resource']['doors_l2_requirement_text']
        else:
            match = re.search('\'(.*)\'', dpExt['resource']['name'])
            
            if match:
                dataProduct['name'] = match.groups()[0]
            
        dataProducts.append(dataProduct)
        
    return dataProducts