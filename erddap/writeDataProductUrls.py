import os

OUT_DIR = '/Users/kerfoot/datasets/OOI/ion'

if not os.path.exists(OUT_DIR):
    print "Write directory does not exist: ", OUT_DIR
else:
        
    for platform in dataProducts.keys():
        
        productFile = OUT_DIR + \
            '/' + dataProducts[platform]['type'] + \
            '_' + \
            platform.replace(' ', '-') + \
            '_' + \
            dataProducts[platform]['id'] + \
            '_dataProducts.csv'
        
        fid = open(productFile, 'w')
        
        for product in dataProducts[platform]['data_products']:
            
            fid.write(product['name'] + ',' + product['id'] + ',' + product['url'] + "\n")
        
        fid.close()
    