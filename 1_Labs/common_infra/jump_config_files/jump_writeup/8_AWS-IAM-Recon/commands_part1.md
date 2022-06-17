AWS credentials should be added in `~/.aws/credentials` (*note*: credentials was
already added to the file on the Kali VM)
```
[aws]
aws_access_key_id={PLACEHOLDER_APP_AWS_ACCESS_KEY_ID}
aws_secret_access_key={PLACEHOLDER_APP_AWS_SECRET_ACCESS_KEY}
```

export AWS_PROFILE=aws

aws sts get-caller-identity
```
{
    "UserId": "AIDA26CUPKHDYXQ3FL3Y3",
    "Account": "751796441543",
    "Arn": "arn:aws:iam::751796441543:user/{PLACEHOLDER_LAB_NAME}_ApplicationDeployment"
}
```

aws iam list-attached-user-policies --user-name {PLACEHOLDER_LAB_NAME}_ApplicationDeployment
```
{
    "AttachedPolicies": [
        {
            "PolicyName": "custom_iam_ro_iam_policy",
            "PolicyArn": "arn:aws:iam::751796441543:policy/custom_iam_ro_iam_policy"
        },
        {
            "PolicyName": "ApplicationRunner",
            "PolicyArn": "arn:aws:iam::751796441543:policy/ApplicationRunner"
        }
    ]
}

```

aws iam get-policy --policy-arn arn:aws:iam::751796441543:policy/ApplicationRunner
```
{
    "Policy": {
        "PolicyName": "ApplicationRunner",
        "PolicyId": "ANPA26CUPKHDUKITJWIMX",
        "Arn": "arn:aws:iam::751796441543:policy/ApplicationRunner",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 1,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "Description": "Allows to deloy a lamba a specific role: lambda:createfunction, invokefunction and iam:passrole",
        "CreateDate": "2022-07-21T14:35:42Z",
        "UpdateDate": "2022-07-21T14:35:42Z"
    }
}
```

aws iam get-policy-version --policy-arn arn:aws:iam::751796441543:policy/ApplicationRunner --version-id v1
```
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "iam:PassRole",
                        "lambda:CreateFunction",
                        "lambda:InvokeFunction"
                    ],
                    "Effect": "Allow",
                    "Resource": "*"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2022-07-21T14:35:42Z"
    }
}
```
