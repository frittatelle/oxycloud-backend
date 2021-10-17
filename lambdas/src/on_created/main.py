
def parse_record(d):
    time = d['eventTime']
    doc = d['s3']['object']
    #format: [REGION]:[COGNITO_USER_ID]/[USER_FILE_PATH]
    full_path = doc['key'] 
    
    #a less error prone way to obtain id exist
    #just look for it
    tmp = full_path.split('%3A')[1]
    user_id = tmp.split("/")[0]
    
    fname = "/".join(tmp.split("/")[1:])
    fsize = doc['size']
    fetag = doc['eTag']

    return (time,user_id),(full_path, fname, fsize, fetag)
    
def lambda_handler(evt, ctx):
    out = []
    for rec in evt['Records']:
        out.append(parse_record(rec))    
    
    print(out)
    return out 

