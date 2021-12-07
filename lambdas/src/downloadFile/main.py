import json
import boto3
import urllib.parse
import base64

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('oxycloud')
s3 = boto3.client('s3')

# TODO: change hardcoded s3 bucket and dynamodb table
# TODO: try catch block
# TODO: get user_id from event

def lambda_handler(event, context):
    
    file_id = event['pathParameters']['id']
    record = table.get_item(
        Key = { 
            'file_id':file_id,
            'user_id':'AROAV6XMGXUC6QVYIKEEB:CognitoIdentityCredentials',
        }
    )
    key = record['Item']['path']
    file_name = record['Item']['display_name']
    
    # s3 call
    s3_object = s3.get_object(Bucket = 'oxycloud', Key = key)
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