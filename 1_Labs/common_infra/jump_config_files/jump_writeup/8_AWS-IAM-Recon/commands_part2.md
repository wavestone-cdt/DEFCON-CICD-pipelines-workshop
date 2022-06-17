
aws iam list-roles

```
[...]
        {
            "Path": "/",
            "RoleName": "CustomAdministratorAccess",
            "RoleId": "AROA26CUPKHDQZFO4HGS5",
            "Arn": "arn:aws:iam::751796441543:role/CustomAdministratorAccess",
            "CreateDate": "2022-07-21T14:35:42Z",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "CustomOldAdministratorAccess",
                        "Effect": "Allow",
                        "Principal": {
                            "AWS": "arn:aws:iam::751796441543:root"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "Description": "Adminitrator",
            "MaxSessionDuration": 3600
        },
[...]
            "Path": "/",
            "RoleName": "ApplicationRoleManager_role",
            "RoleId": "AROA26CUPKHDR5GFQG75R",
            "Arn": "arn:aws:iam::751796441543:role/ApplicationRoleManager_role",
            "CreateDate": "2022-07-21T15:10:57Z",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "lambda.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }
                ]
            },
            "MaxSessionDuration": 3600
        },
[...]
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

aws iam list-attached-role-policies --role-name ApplicationRoleManager_role
```
{
    "AttachedPolicies": [
        {
            "PolicyName": "ApplicationRoleManager",
            "PolicyArn": "arn:aws:iam::751796441543:policy/ApplicationRoleManager"
        }
    ]
}
```

aws iam get-policy-version --policy-arn  arn:aws:iam::751796441543:policy/ApplicationRoleManager --version-id v1
```
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": "iam:AttachUserPolicy",
                    "Effect": "Allow",
                    "Resource": "*"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2022-07-21T15:16:27Z"
    }
}

```
