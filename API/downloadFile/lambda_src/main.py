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
    record = table.get_item(
        Key = { 
            'file_id':file_id,
            'user_id':user_id,
        }
    )
    key = record['Item']['file_id']
    file_name = record['Item']['display_name']
    
    # s3 signed url
    url = s3.generate_presigned_url('get_object',
        Params={'Bucket': bucket, 'Key': key},
        ExpiresIn=lifetime
    )
    print(url)
    
    return {
        'statusCode':200,
        'body': url,
    }

