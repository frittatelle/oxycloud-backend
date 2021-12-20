import json
import boto3
import base64
import os

table = os.environ['USER_STORAGE_TABLE']
table = boto3.resource('dynamodb').Table(table)

# TODO: try catch block
def mk_update(file_id,user_id,doomed,deleted,tbl_name):
    return {'Update': {
                'Key': {
                    'file_id':file_id,
                    'user_id':user_id
                },
                'UpdateExpression': 'SET is_doomed = :doomed, is_deleted = :deleted',
                'ExpressionAttributeValues': {
                    ':deleted': deleted,
                    ':doomed': doomed

                },
                'TableName':tbl_name
            }}

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

def update_children(user_id,folder_id,doomed,deleted):
    res = table.query(
        KeyConditionExpression="user_id = :user", 
        FilterExpression="folder = :folder",
        ProjectionExpression="file_id",
        ExpressionAttributeValues={
            ":user":user_id,
            ":folder":folder_id
    })

    updates = [
        mk_update(it['file_id'],user_id,doomed,deleted,table.name) 
        for it in res['Items']
    ]

    for chunk in chunks(updates,25):
        table.meta.client.transact_write_items(TransactItems=chunk)
    return len(updates)

def lambda_handler(event, context):    
    results = []
    for record in event['Records']:
        record = record['dynamodb']['NewImage']
        user_id = record['user_id']['S']
        folder_id = record['file_id']['S']
        doom = record['is_doomed']['BOOL']
        deleted = record['is_deleted']['BOOL']
        
        res = update_children(user_id,folder_id,doom,deleted)
        results.append((folder_id,res))

    return json.dumps(results)



