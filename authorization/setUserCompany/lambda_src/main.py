import json
import boto3

user_pool = boto3.client('cognito-idp')

def lambda_handler(event, context):

    email = event['request']['userAttributes']['cognito:email_alias'].split('@')
    domain = email[1]
    
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
    
    return event
