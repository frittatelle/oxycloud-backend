import os
import uuid

from botocore.exceptions import ClientError
import boto3

#raises an error on missing env. variable
TABLE_NAME = os.environ['USER_STORAGE_TABLE']

def parse_record(d):
    parsed = {}
    parsed['time'] = d['eventTime']
    doc = d['s3']['object']
    #format: [REGION]:[COGNITO_USER_ID]/[USER_FILE_PATH]
    parsed['full_path'] = doc['key'] 
    
    #a less error prone way to obtain id exist
    #just look for it
    tmp = doc['key'].split('%3A')[1]
    parsed['user_id'] = tmp.split("/")[0]
    
    parsed['fname'] = "/".join(tmp.split("/")[1:])
    parsed['fsize'] = doc['size']
    parsed['fetag'] = doc['eTag']

    return parsed 

def put_records(records):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(TABLE_NAME)
    #TODO: check existence of a file with the same full path 
    #    and probably somethingelse. You can't do everything, can you? 
    for r in records:
        try:
            table.put_item(Item={'file_id':str(uuid.uuid4()), **r})
        except ClientError as e:
            print(e.response['Error']['Message'])
            

def lambda_handler(evt, ctx):
    records = [parse_record(rec) for rec in evt['Records']]
    try:
        put_records(records)
    except Exception as e:
        print(e)
    return records 



