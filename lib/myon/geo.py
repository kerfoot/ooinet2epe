
def resource2geoJson(resource):
    
    geoJson = {}
    
    if 'constraint_list' not in resource:
        return geoJson
        
    north = resource['constraint_list'][0]['geospatial_latitude_limit_north']
    south = resource['constraint_list'][0]['geospatial_latitude_limit_south']
    east = resource['constraint_list'][0]['geospatial_longitude_limit_east']
    west = resource['constraint_list'][0]['geospatial_longitude_limit_west']
    min_depth = resource['constraint_list'][0]['geospatial_vertical_min']
    max_depth = resource['constraint_list'][0]['geospatial_vertical_max']
    
    geoJson = {'type' : '',
        'coordinates' : [],
        'properties' : {'geospatial_vertical_min' : min_depth,
            'geospatial_vertical_max' : max_depth}}
        
    if north == south and east == west:
        # Point
        geoJson['type'] = 'Point'
        geoJson['coordinates'] = [west, north]
    else:
        # Polygon
        geoJson['type'] = 'Polygon'
        geoJson['coordinates'] = [[west, north],
            [east, north],
            [east, south],
            [west, south],
            [west, north]]
    
    if 'coordinate_reference_system' in resource:
        geoJson['crs'] = {'type' : 'URL',
            'properties' : {'url' : resource['coordinate_reference_system']['geospatial_geodetic_crs'] }}
            
    return geoJson