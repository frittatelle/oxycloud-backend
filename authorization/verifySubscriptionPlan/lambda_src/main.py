import json
import boto3

def verify_subscription_plan(subscription_plan):
    if subscription_plan not in ["50", "100", "500"]:
        return False
    # payment system verification
    return True

def lambda_handler(event, context):
    
    subscription_plan = event['request']['userAttributes']['custom:subscription_plan']

    if not verify_subscription_plan(subscription_plan):
        raise Exception("Subscription plan is not verified")
    else:
        event['response']['autoConfirmUser'] = True
    
    return event
