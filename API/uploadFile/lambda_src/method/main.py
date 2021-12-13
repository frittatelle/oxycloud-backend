import json
import boto3
import base64
import os
import uuid

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
lifetime = os.environ.get("PRESIGNED_URL_LIFETIME",300)
bucket = os.environ['USER_STORAGE_BUCKET']

# TODO: try catch block

def lambda_handler(event, context):
    
    user_id     = event['requestContext']['authorizer']['claims']['cognito:username']
    company     = event['requestContext']['authorizer']['claims']['custom:company']
    file_name   = event["queryStringParameters"]['filename']
    
    key = f"{company}/{user_id}/{str(uuid.uuid4())}"
    # s3 signed url
    res = s3.generate_presigned_post(bucket, 
        key, 
        Fields={
            "x-amz-meta-displayname":file_name,
            "x-amz-meta-user":user_id,
        }, 
        ExpiresIn=lifetime
    )
    
    return {
        'statusCode':200,
        'body': json.dumps(res),
    }


