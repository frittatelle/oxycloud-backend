import json
import boto3
import urllib.parse
import uuid
import os
from base64 import b64decode

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_STORAGE_TABLE'])
users_table = dynamodb.Table(os.environ['USERS_TABLE'])
s3 = boto3.client('s3')
bucket = os.environ['USER_STORAGE_BUCKET']

def lambda_handler(event, context):
    for record in event['Records']:
        key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
        size = record['s3']['object']['size']
        eTag = urllib.parse.unquote_plus(record['s3']['object']['eTag'], encoding='utf-8')
        time = record['eventTime']

        head = s3.head_object(Bucket = bucket,Key = key)
        user = head['Metadata']['user']
        display_name = head['Metadata']['displayname']
        display_name = b64decode(display_name).decode('utf8')
        folder = head['Metadata']['folder']

        file_id = key.split("/")[-1]
        #add to storage table
        table.put_item(
            Item={
                'file_id': file_id,
                'user_id': user,
                'display_name': display_name,
                'size': size,
                'eTag': eTag,
                'time': time,
                'folder': folder,
                'is_folder': False,
                'is_deleted': False,
                'is_doomed': False
            }
        )
        #update used storage
        users_table.update_item(
            Key={ 'user_id': user },
            UpdateExpression="set used_space = used_space + :size",
            ExpressionAttributeValues={ ':size': size },
            ReturnValues="UPDATED_NEW"
        )
