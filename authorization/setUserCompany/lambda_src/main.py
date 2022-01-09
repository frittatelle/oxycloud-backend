import json
import boto3
import os
user_pool = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')

users_table = dynamodb.Table(os.environ['USERS_TABLE'])
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
    total = int(int(event['request']['userAttributes']['custom:subscription_plan']) * 1e9)#GB
    users_table.put_item(
            Item={
                'user_id': event['userName'],
                'company': domain,
                'used_space': 0,
                'total_space': total
            }
        )


    return event
