import json
import boto3
import base64
import os

s3 = boto3.client('s3')
bucket = os.environ['USER_STORAGE_BUCKET']

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ['USERS_TABLE'])

def lambda_handler(event, context):
    for record in event['Records']:
        record = record['dynamodb']['NewImage']
        key = record['file_id']['S']
        user = record['user_id']['S']
        size = int(record['size']['N'])

        try:
            res = s3.delete_object(Bucket = bucket, Key = key)
        except:
            print(f"Error permanent deleting {key} on {bucket}")
        #update used storage
        users_table.update_item(
            Key={ 'user_id': user },
            UpdateExpression="set used_space = used_space - :size",
            ExpressionAttributeValues={ ':size': size },
            ReturnValues="UPDATED_NEW"
        )
