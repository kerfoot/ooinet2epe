import re
import myon.constants
import myon.catalogs.ObservatoryManagement

# Set the ION service gateway url
myon.http.ION_URL = myon.constants.ION_B_URL

# Observatory resource id: Global Station Papa Mobile Assets
observatory_id = 'aabe98f9d4f14be4b8fb7fd61dd27047'

# Fetch the Observatory extension object
obsExt = myon.catalogs.ObservatoryManagement.getObservatorySiteExtension(observatory_id)

platforms = obsExt['platform_station_sites']

dataProducts = {}

platformService = 'observatory_management'
platformAction = 'get_platform_station_site_extension'
platformParams = {'site_id' : ''}

productService = 'data_product_management'
productAction = 'get_data_product_extension'
productParams = {'data_product_id' : ''}

for platform in platforms:
    
    platformName = platform['local_name']
    
    print platformName, ": Fetching data products..."
    
    dataProducts[platformName] = {'id' : platform['_id'],
        'type' : obsExt['resource']['reference_designator'],
        'data_products' : []}
    
    platformParams['site_id'] = platform['_id']
    
    url = myon.http.createIonUrl(platformService, platformAction, platformParams)
    
    response = myon.http.getRequest(url)
    
    if 'GatewayError' in response['data']:
        print response['data']['Message']
        continue
    
    platformExt = response['data']['GatewayResponse']
    
    platformProducts = platformExt['data_products']
    
    for dp in platformProducts:
        
        print "Product: ", dp['name']
        
        productParams['data_product_id'] = dp['_id']
        
        productUrl = myon.http.createIonUrl(productService, productAction, productParams)
        
        productResponse = myon.http.getRequest(productUrl)
        
        if 'GatewayError' in response['data']:
            print response['data']['Message']
            continue
            
        productExt = productResponse['data']['GatewayResponse']
        
        # ERDDAP url
        erddapUrl = productExt['computed']['data_url']['value']
        
        # Create the name
        productName = productExt['resource']['ooi_short_name']
        if not productName:
            m = re.compile('\'(.*)\'').search(productExt['resource']['name'])
            productName = m.groups()[0]
        
        productMeta = { 'name' : productName,
            'id' : productExt['resource']['_id'],
            'url' : erddapUrl}
            
        dataProducts[platformName]['data_products'].append(productMeta)

        