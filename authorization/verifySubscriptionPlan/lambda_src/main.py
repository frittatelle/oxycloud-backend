import json
import boto3

def verify_subscription_plan(subscription_plan):
    if subscription_plan not in [50, 100, 500]:
        return false
    # payment system verification
    return true

def lambda_handler(event, context):
    
    subscription_plan = event['request']['userAttributes']['subscription_plan']

    if not verify_subscription_plan(subscription_plan):
        raise Exception("Subscription plan is not verified")
    
    return event
