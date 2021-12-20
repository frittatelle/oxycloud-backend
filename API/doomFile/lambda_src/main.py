import json
import boto3
import base64
import os

s3 = boto3.client('s3')
bucket = os.environ['USER_STORAGE_BUCKET']

# TODO: try catch block

def lambda_handler(event, context):
    
    key = event['Records'][0]['dynamodb']['NewImage']['file_id']['S']
    res = s3.delete_object(Bucket = bucket, Key = key)

    return {
        'statusCode': 200,
        'body': json.dumps(f'{key} deleted from S3 bucket')
    }


