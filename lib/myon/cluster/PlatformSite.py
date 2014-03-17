import myon.http
from operator import itemgetter

def getPlatformSite(resource_id):
    
    platform = {}
    
    # Fetch the metadata for the resource
    resource_response = myon.http.readResourceId(resource_id)
    
    if 'GatewayError' in resource_response['data']:
        exception = resource_response['data']['GatewayError']['Exception']
        message = resource_response['data']['GatewayError']['Message']
        raise exception(message)    
    
    # Process only PlatformSite resources
    if resource_response['data']['GatewayResponse']['type_'] != 'PlatformSite':
        return platform
        
    platform_meta = resource_response['data']['GatewayResponse']
    
    name = platform_meta['local_name']
    if not name:
        name = platform_meta['name']
        
    platform = {'name' : name,
        'full_name' : platform_meta['name'],
        'resource_id' : platform_meta['_id'],
        'available' : True if platform_meta['availability'] == 'AVAILABLE' else False,
        'deployed' : True if platform_meta['lcstate'] == 'DEPLOYED' else False,
        'ts_created' : platform_meta['ts_created'],
        'ts_updates' : platform_meta['ts_updated'],
        'restype' : platform_meta['type_'],
        'geometry' : myon.geo.resource2geoJson(platform_meta),
        'description' : platform_meta['description'],
        'children' : []}
        
    return platform
    
def groupPlatformSitesDataProducts(platforms):
    
    product_groups = {}
    
    url_tokens = {'service' : 'observatory_management',
        'action' : 'get_platform_station_site_extension',
        'params' : {'site_id' : ''}}
        
    for platform in platforms:
        
        url_tokens['params']['site_id'] = platform['resource_id']
        
        url = myon.http.createIonUrl(url_tokens['service'], url_tokens['action'], url_tokens['params'])
        
        response = myon.http.getRequest(url)
        
        if 'GatewayResponse' not in response['data']:
            continue
        
        site_extension = response['data']['GatewayResponse']
        data_products = site_extension['data_products']
    
        for data_product in data_products:
            
            if not data_product['ooi_product_name']:
                continue
                
            if data_product['ooi_product_name'] not in product_groups.keys():
                p_levels = {'L0' : {'children' : []},
                    'L1' : {'children' : []},
                    'L2' : {'children' : []}}
                product_groups[data_product['ooi_product_name']] = {'children' : p_levels}
            
            min_depth = data_product['geospatial_bounds']['geospatial_vertical_min']
            max_depth = data_product['geospatial_bounds']['geospatial_vertical_max']
            
            product_label = platform['name']
            depth_string = '';
            if min_depth == max_depth:
                product_label += ' @ {:0.0f} m'.format(min_depth)
                depth_string = '{:0.0f} m'.format(min_depth)
            else:
                product_label += ' @ {:0.0f} - {:0.0f} m'.format(min_depth, max_depth)
                depth_string = '{:0.0f} - {:0.0f} m'.format(min_depth, max_depth)
                
            product_meta = {'ooi_product_name' : data_product['ooi_product_name'],
                'description' : data_product['name'],
                'resource_id' : data_product['_id'],
                'restype' : data_product['type_'],
                'processing_level_code' : data_product['processing_level_code'],
                'ooi_short_name' : data_product['ooi_short_name'],
                'children' : [],
                'name' : product_label,
                'platform' : platform['name'],
                'depth_string' : depth_string,
                'geospatial_vertical_min' : min_depth,
                'geospatial_vertical_max' : max_depth}
            
            product_groups[data_product['ooi_product_name']]['children'][data_product['processing_level_code']]['children'].append(product_meta)
         
    for product in product_groups.keys():
        
        pgroup_children = []
        
        for level in product_groups[product]['children'].keys():
            
            sorted_children = sorted(product_groups[product]['children'][level]['children'], key=itemgetter('platform', 'geospatial_vertical_min'))
            children = {'name' : level,
                'children' : sorted_children}
            
            pgroup_children.append(children)
      
        product_groups[product]['children'] = sorted(pgroup_children, key=itemgetter('name'))
            
    return product_groups

def groupPlatformSiteDataProducts(resource_id):
    
    product_groups = {}
    
    response = myon.http.readResourceId(resource_id)
    if 'GatewayResponse' not in response['data']:
        print 'Error retrieving resource: {:s}'.format(resource_id)
        return product_groups
    elif response['data']['GatewayResponse']['type_'] != 'PlatformSite':
        print 'Resource is not a PlatformSite: {:s}'.format(resource_id)
        return product_groups
        
    url_tokens = {'service' : 'observatory_management',
        'action' : 'get_platform_station_site_extension',
        'params' : {'site_id' : response['data']['GatewayResponse']['_id']}}
        
    url = myon.http.createIonUrl(url_tokens['service'], url_tokens['action'], url_tokens['params'])
    
    response = myon.http.getRequest(url)
    
    if 'GatewayResponse' not in response['data']:
        print 'Error retrieving resource: {:s}'.format(resource_id)
        return product_groups
    
    site_extension = response['data']['GatewayResponse']
    data_products = site_extension['data_products']

    for data_product in data_products:
        
        if not data_product['ooi_product_name']:
            continue
            
        if data_product['ooi_product_name'] not in product_groups.keys():
            p_levels = {'L0' : {'children' : []},
                'L1' : {'children' : []},
                'L2' : {'children' : []}}
            product_groups[data_product['ooi_product_name']] = {'children' : p_levels}
        
        min_depth = data_product['geospatial_bounds']['geospatial_vertical_min']
        max_depth = data_product['geospatial_bounds']['geospatial_vertical_max']
        
        product_label = platform['name']
        depth_string = '';
        if min_depth == max_depth:
            product_label += ' @ {:0.0f} m'.format(min_depth)
            depth_string = '{:0.0f} m'.format(min_depth)
        else:
            product_label += ' @ {:0.0f} - {:0.0f} m'.format(min_depth, max_depth)
            depth_string = '{:0.0f} - {:0.0f} m'.format(min_depth, max_depth)
            
        product_meta = {'ooi_product_name' : data_product['ooi_product_name'],
            'description' : data_product['name'],
            'resource_id' : data_product['_id'],
            'restype' : data_product['type_'],
            'processing_level_code' : data_product['processing_level_code'],
            'ooi_short_name' : data_product['ooi_short_name'],
            'children' : [],
            'name' : product_label,
            'platform' : platform['name'],
            'depth_string' : depth_string,
            'geospatial_vertical_min' : min_depth,
            'geospatial_vertical_max' : max_depth}
        
        product_groups[data_product['ooi_product_name']]['children'][data_product['processing_level_code']]['children'].append(product_meta)
         
    for product in product_groups.keys():
        
        pgroup_children = []
        
        for level in product_groups[product]['children'].keys():
            
            sorted_children = sorted(product_groups[product]['children'][level]['children'], key=itemgetter('platform', 'geospatial_vertical_min'))
            children = {'name' : level,
                'children' : sorted_children}
            
            pgroup_children.append(children)
      
        product_groups[product]['children'] = sorted(pgroup_children, key=itemgetter('name'))
            
    return product_groups