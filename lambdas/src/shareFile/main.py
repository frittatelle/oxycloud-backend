import json
import boto3
import urllib.parse
import base64

# TODO: change hardcoded userpool id and dynamodb table
# TODO: try catch block

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('oxycloud')
user_pool = boto3.client('cognito-idp')


def lambda_handler(event, context):

    share_email = event['queryStringParameters']['share_email']
    file_id = event['pathParameters']['id']
    user_id = event['requestContext']['authorizer']['claims']['cognito:username']
    
    # get share user 
    user_pool_res = user_pool.list_users(
            UserPoolId = 'us-east-1_wfp8OJTSc',
            Limit = 1,
            Filter = "email = \"{}\"".format(share_email)
        )
    share_username = user_pool_res['Users'][0]['Username']
        
    # update share list
    res = table.update_item(
        Key = { 
            'file_id':file_id,
            'user_id':user_id
        },
        UpdateExpression='add shared_with :share_username',
        ConditionExpression='file_id = :file_id AND user_id = :user_id',
        ExpressionAttributeValues={
            ':share_username':set([share_username]),
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