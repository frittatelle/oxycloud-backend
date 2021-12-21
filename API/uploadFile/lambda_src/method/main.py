import json
import boto3
import os
import uuid
from datetime import datetime
from botocore.config import Config
from base64 import b64encode

lifetime = os.environ.get("PRESIGNED_URL_LIFETIME",300)
bucket = os.environ['USER_STORAGE_BUCKET']
TABLE = os.environ['USER_STORAGE_TABLE']
def encode(data):
    encodedBytes = b64encode(data.encode("utf-8"))
    return str(encodedBytes, "utf-8")
# TODO: try catch block

def lambda_handler(event, context):
    user_id     = event['requestContext']['authorizer']['claims']['cognito:username']
    company     = event['requestContext']['authorizer']['claims']['custom:company']
    file_name   = event["queryStringParameters"]['filename']
    is_folder   = bool(event["queryStringParameters"].get('is_folder',False))
    folder      = event["queryStringParameters"].get('folder','')
    if is_folder:
        dyndb = boto3.resource("dynamodb")
        table = dyndb.Table(TABLE)
        time = str(datetime.utcnow()).replace(" ","T") + "Z"
        response = table.put_item(
                Item={
                    'file_id': str(uuid.uuid4()),
                    'user_id': user_id,
                    'display_name': file_name, 
                    'size': 0,
                    'eTag': "",
                    'time': time,
                    'folder': folder,
                    'is_folder': True,
                    'is_deleted': False,
                    'is_doomed': False
                }
            )

        return {'statusCode':200}
    else:
        s3 = boto3.client('s3', config=Config(signature_version = 's3v4'))
        key = str(uuid.uuid4())
        file_name = encode(file_name)
        # s3 signed url
        res = s3.generate_presigned_post(bucket, 
            key, 
            Fields={
                "x-amz-meta-displayname": file_name, 
                "x-amz-meta-folder": folder, 
                "x-amz-meta-user":user_id,
            }, 
            Conditions=[
                ['eq','$x-amz-meta-user',user_id],
                ['eq','$x-amz-meta-displayname',file_name],
                ['eq','$x-amz-meta-folder',folder],
                ['eq', '$key',key]
            ],
            ExpiresIn=lifetime
        )
        
        return {
            'statusCode':200,
            'body': json.dumps(res),
        }


