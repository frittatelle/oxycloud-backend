import json
import boto3
import os

user_pool = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ['USERS_TABLE'])

def verify_subscription_plan(subscription_plan):
    if subscription_plan not in [50*1e9, 100*1e9, 500*1e9]:
        return False
    # payment system verification
    return True

def lambda_handler(event, context):
    
    print(event)
    
    subscription_plan = int(int(event['request']['clientMetadata']['Value']) * 1e9)#GB

    # check subscription plan
    if not verify_subscription_plan(subscription_plan):
        raise Exception("Subscription plan is not verified")
    else:
        # autoconfirm user
        event['response']['autoConfirmUser'] = True
        # update users table
        users_table.put_item(
            Item = {
                'user_id': event['userName'],
                'used_space': 0,
                'total_space': subscription_plan
            }
        )
    
    return event
