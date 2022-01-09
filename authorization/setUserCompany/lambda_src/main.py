import json
import boto3
import os

user_pool = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ['USERS_TABLE'])

def lambda_handler(event, context):

    email = event['request']['userAttributes']['cognito:email_alias'].split('@')
    domain = email[1]

    # update user pool with company
    res = user_pool.admin_update_user_attributes(
        UserPoolId=event['userPoolId'],
        Username=event['userName'],
        UserAttributes=[
            {
                'Name': 'custom:company',
                'Value': domain
            }
        ],
    )

    # update user table with company
    users_table.update_item(
        Key = {
            'user_id': event['userName']
        },
        UpdateExpression='set company = :company',
        ConditionExpression='user_id = :user_id',
        ExpressionAttributeValues={
            ':company': domain,
            ':user_id': event['userName']
        },
        ReturnValues='UPDATED_NEW'
    )

    return event
