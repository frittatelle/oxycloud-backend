import json
import boto3
import urllib.parse
import uuid
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_STORAGE_TABLE'])
s3 = boto3.client('s3')
bucket = os.environ['USER_STORAGE_BUCKET']

# TODO: try catch block

def lambda_handler(event, context):

    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    size = event['Records'][0]['s3']['object']['size']
    eTag = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['eTag'], encoding='utf-8')
    time = event['Records'][0]['eventTime']

    print(key)

    head = s3.head_object(Bucket = bucket,Key = key)
    user = head['Metadata']['user']
    display_name = head['Metadata']['displayname']

    response = table.put_item(
        Item={
            'file_id': str(uuid.uuid4()),
            'user_id': user,
            'display_name': display_name,
            'path': key,
            'size': size,
            'eTag': eTag,
            'time': time
        }
    )

    return response
