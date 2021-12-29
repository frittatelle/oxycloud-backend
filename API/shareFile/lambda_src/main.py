import json
import boto3
import urllib.parse
import base64
import os

# TODO: try catch block

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_STORAGE_TABLE'])
user_pool = boto3.client('cognito-idp')
user_pool_id = os.environ['USER_POOL_ID']

def lambda_handler(event, context):

    share_email = event['queryStringParameters']['share_email']
    file_id = event['pathParameters']['id']
    user_id = event['requestContext']['authorizer']['claims']['cognito:username']
    
    # check if user exists in user pool
    user_pool_res = user_pool.list_users(
            UserPoolId = user_pool_id,
            Limit = 1,
            Filter = "email = \"{}\"".format(share_email)
        )
    
    # share_username = user_pool_res['Users'][0]['Attributes'][0]['Value']
    if len(user_pool_res['Users']) > 0:  
        # update share list
        res = table.update_item(
            Key = { 
                'file_id':file_id,
                'user_id':user_id
            },
            UpdateExpression='add shared_with :share_username',
            ConditionExpression='file_id = :file_id AND user_id = :user_id',
            ExpressionAttributeValues={
                ':share_username':set([share_email]),
                ':file_id':file_id,
                ':user_id':user_id
            },
            ReturnValues='UPDATED_NEW'
        )
    
    return {
        "isBase64Encoded": "true",
        "statusCode": 200,
        "headers":{
            "Content-Type":"application/json"
        }
    }