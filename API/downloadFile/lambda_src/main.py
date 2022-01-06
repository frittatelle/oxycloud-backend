import json
import boto3
import base64
import os

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
lifetime = os.environ.get("PRESIGNED_URL_LIFETIME",300)
table = dynamodb.Table(os.environ['USER_STORAGE_TABLE'])
bucket = os.environ['USER_STORAGE_BUCKET']

# TODO: try catch block

def lambda_handler(event, context):
    
    file_id = event['pathParameters']['id']
    user_id = event['requestContext']['authorizer']['claims']['cognito:username']
    try:
        record = table.get_item(
            Key = {
                'user_id':user_id,
                'file_id':file_id,
            }
        )
        if 'Item' not in record:
            #the user isn't the owner or the files doesn't exist
            # if owner_id params is avaible check if the owner
            # shared the file with this user
            owner_id = event['queryStringParameters']['owner_id']
            record = table.get_item(
                    Key = {
                        'user_id':owner_id,
                        'file_id':file_id,
                    }
            )
            if user_id not in record['Item']['shared_with']:
                raise "not authorized"
        if bool(record['Item']['is_doomed']):
            raise "file doesn't exist anymore"
    except:
            return { 
                    'statusCode':400,
                    'body':{'message':'file not found'}
            }
        
    key = record['Item']['file_id']
    file_name = record['Item']['display_name']
    
    # s3 signed url
    url = s3.generate_presigned_url('get_object',
        Params={'Bucket': bucket, 'Key': key},
        ExpiresIn=lifetime
    )
    
    return {
        'statusCode':200,
        'body': url,
    }

