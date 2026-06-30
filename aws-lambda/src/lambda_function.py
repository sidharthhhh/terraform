import json

def lambda_handler(event, context):
    print("Event:", event)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from your new Python Lambda Function!')
    }
