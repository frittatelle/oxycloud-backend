import json
import boto3
import urllib.parse
import uuid
import os
from base64 import b64decode

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

    head = s3.head_object(Bucket = bucket,Key = key)
    user = head['Metadata']['user']
    display_name = head['Metadata']['displayname']
    display_name = b64decode(display_name).decode('utf8')

    folder = display_name.split("/")
    if len(folder)>1:
        folder = "/".join(folder[:-1])
    else:
        folder = ""
    
    response = table.put_item(
        Item={
            'file_id': str(uuid.uuid4()),
            'user_id': user,
            'display_name': display_name, #is full path necessary?
            'path': key,
            'size': size,
            'eTag': eTag,
            'time': time,
            'folder': folder,
            'is_folder': False
        }
    )

    return response
