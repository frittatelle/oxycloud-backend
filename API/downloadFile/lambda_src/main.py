import json
import boto3
import base64
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_STORAGE_TABLE'])
s3 = boto3.client('s3')
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
    key = record['Item']['path']
    file_name = record['Item']['display_name']
    
    # s3 call
    s3_object = s3.get_object(Bucket = bucket, Key = key)
    file_content = s3_object['Body'].read()
    res = {
        'statusCode':200,
        'headers':{
            'Content-Type':s3_object['ContentType'],
            'Content-Disposition':"attachment; filename={}".format(file_name)
        },
        'body': base64.b64encode(file_content),
        'isBase64Encoded': True
    }

    
    return res