/*
======================================
INFRA : Create a custom iam role to give EC2 access to the S3 configuration bucket
======================================
*/


resource "aws_iam_role" "master_role" {
    name = lower("${var.name}-${var.region}")

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "master_profile" {
    name = lower("${var.name}-${var.region}")
    role = aws_iam_role.master_role.name
}

resource "aws_iam_policy" "write_secrets_policy_jump" {
    name        = "${var.name}-write-secrets"
    description = "A test policy"

    policy =   <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "${aws_s3_bucket.jump_bucket.arn}",
                "${aws_s3_bucket.jump_bucket.arn}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "master_node_attachement" {
    name       = "Master node attachement"
    roles      = ["${aws_iam_role.master_role.name}"]
    policy_arn = "${aws_iam_policy.write_secrets_policy_jump.arn}"
}


/*
======================================
INFRA : Instanciate the roles necessary for EKS
======================================
*/


module "k8s_iam" {
    source            = "./modules/eks_role"
    eks_role_name     = "${ var.name }-EKS-Cluster-Role"
    workers_role_name = "${ var.name }-EKS-Workers-Role"
}


/*
======================================
Instanciate the roles to perform a privilege AWS privilege escalation
SRC : Lambda Pass role - PassExistingRoleToNewLambdaThenInvoke
Based on https://github.com/BishopFox/iam-vulnerable/
======================================
*/

## Part 1 : Create the entry point iam user with passrole

resource "aws_iam_policy" "ApplicationDeploymentPolicy" {
  provider    = aws.src
  name        = "ApplicationRunner"
  path        = "/"
  description = "Allows to deloy a lamba a specific role: lambda:createfunction, invokefunction and iam:passrole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
 			  "iam:PassRole",
			  "lambda:CreateFunction",
			  "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

/*resource "aws_iam_user" "ApplicationDeployment_user" {
  provider = aws.src
  name = "ApplicationDeployment_user"
  path = "/"
}

resource "aws_iam_access_key" "ApplicationDeployment_user" {
  provider = aws.src
  user = aws_iam_user.ApplicationDeployment_user.name
}


resource "aws_iam_user_policy_attachment" "ApplicationDeployment_user_attach_policy_passrole" {
  provider   = aws.src
  user       = aws_iam_user.ApplicationDeployment_user.name
  policy_arn = aws_iam_policy.ApplicationDeploymentPolicy.arn
}
*/

data "aws_iam_policy_document" "src_custom_iam_ro_src_iam_policy_doc" {
  provider    = aws.src
  statement {
    sid        = "CustomIamPolicy1"
    effect     = "Allow"
    actions    = ["iam:Get*","iam:List*"]
    resources  = [
        "arn:aws:iam::${data.aws_caller_identity.src.account_id}:role/*",
        "arn:aws:iam::${data.aws_caller_identity.src.account_id}:user/*",
        "arn:aws:iam::${data.aws_caller_identity.src.account_id}:policy/*"
      ]
  }
}

resource "aws_iam_policy" "src_custom_iam_ro_src_iam_policy" {
  provider    = aws.src
  name        = "custom_iam_ro_iam_policy"
  description = "Allow to use specific IAM actions"
  policy = data.aws_iam_policy_document.src_custom_iam_ro_src_iam_policy_doc.json
}

/*
resource "aws_iam_user_policy_attachment" "ApplicationDeployment_user_attach_policy_iam_ro" {
  provider   = aws.src
  user       = aws_iam_user.ApplicationDeployment_user.name
  policy_arn = aws_iam_policy.src_custom_iam_ro_src_iam_policy.arn
}*/

## Part 2 : Create the iam role that will be passed to the labmda to attach a new policy

resource "aws_iam_policy" "ApplicationRoleManager" {
  provider    = aws.src
  name        = "ApplicationRoleManager"
  path        = "/"
  description = "Allows to attach a role via iam:AttachRolePolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:AttachUserPolicy"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ApplicationRoleManager_role" {
  provider    = aws.src
  name                = "ApplicationRoleManager_role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ApplicationRoleManager_AttachRolePolicy" {
  provider    = aws.src
  role       = aws_iam_role.ApplicationRoleManager_role.name
  policy_arn = aws_iam_policy.ApplicationRoleManager.arn
}

/*
======================================
SRC : Instanciate the roles necessary for AWS lateral movement
Thanks to Arnaud PETITCOL (Wavestone), AWS Master
======================================
*/

## Role custom AdministratorAccess

resource "aws_iam_role" "src_OldAdministratorAccess" {
  provider    = aws.src
  name = "CustomAdministratorAccess"
  description = "Adminitrator of the AWS account"
  assume_role_policy = data.aws_iam_policy_document.src_OldAdministratorAccess_assumerole_policy_doc.json
}

data "aws_iam_policy_document" "src_OldAdministratorAccess_assumerole_policy_doc" {
  provider    = aws.src
  statement {
    sid        = "CustomOldAdministratorAccess"
    effect     = "Allow"
    actions    = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.src.account_id]
    }
  }
}

resource "aws_iam_role_policy_attachment" "src_OldAdministratorAccess_AA" {
    provider    = aws.src
    role       = aws_iam_role.src_OldAdministratorAccess.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "src_OldAdministratorAccess_RO_DST" {
    provider   = aws.src
    role       = aws_iam_role.src_OldAdministratorAccess.name
    policy_arn = aws_iam_policy.src_OldAdministratorAccess_RO_DST_policy.arn
}

data "aws_iam_policy_document" "src_custom_iam_ro_src_dst_iam_policy_doc" {
  provider    = aws.src
  statement {
    sid        = "CustomIamPolicy1"
    effect     = "Allow"
    actions    = ["iam:Get*","iam:List*", "iam:UpdateAssume*"]
    resources  = [
        "arn:aws:iam::${data.aws_caller_identity.src.account_id}:role/*",
        "arn:aws:iam::${data.aws_caller_identity.src.account_id}:policy/*"
      ]
  }
  statement {
    sid        = "CustomIamPolicy2"
    effect     = "Allow"
    actions    = ["sts:AssumeRole"]
    resources  = [
        "arn:aws:iam::${data.aws_caller_identity.src.account_id}:role/*",
        "arn:aws:iam::${data.aws_caller_identity.dest.account_id}:role/${var.dest_iam_ro_role_name}"
      ]
  }
}

resource "aws_iam_policy" "src_OldAdministratorAccess_RO_DST_policy" {
  provider    = aws.src
  name        = "src_custom_iam_ro_src_dst_iam_policy"
  description = "Allow to use specific IAM actions"
  policy = data.aws_iam_policy_document.src_custom_iam_ro_src_dst_iam_policy_doc.json
}

## Role custom to perform lateral movement

resource "aws_iam_role" "src_lambda_role" {
  provider    = aws.src
  name = "${var.src_lambda_to_admin_master_role_name}"
  assume_role_policy = data.aws_iam_policy_document.src_lambda_assumerole_policy_doc.json
}

data "aws_iam_policy_document" "src_lambda_assumerole_policy_doc" {
  provider    = aws.src
  statement {
    sid        = "CustomLambdaRole"
    effect     = "Allow"
    actions    = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.src.account_id]
    }
  }
}

resource "aws_iam_role_policy_attachment" "src_lambda_role_iam_admin_policy_attachment" {
    provider    = aws.src
    role       = aws_iam_role.src_lambda_role.name
    policy_arn = aws_iam_policy.src_custom_iam_assume_admin_role_master_iam_policy.arn
}

data "aws_iam_policy_document" "src_custom_iam_assume_admin_role_master_iam_policy_doc" {
  provider    = aws.src
  statement {
    sid        = "CustomAssumeAdminRoleMasterPolicy"
    effect     = "Allow"
    actions    = ["sts:AssumeRole"]
    resources  = ["arn:aws:iam::${data.aws_caller_identity.dest.account_id}:role/${var.dest_admin_role_name}"]
  }
}

resource "aws_iam_policy" "src_custom_iam_assume_admin_role_master_iam_policy" {
  provider    = aws.src
  name        = "custom_iam_assume_admin_role_master"
  description = "Allow to assume admin role in MASTER account named ${var.dest_admin_role_name}"
  policy = data.aws_iam_policy_document.src_custom_iam_assume_admin_role_master_iam_policy_doc.json
}


/*
======================================
DEST : Instanciate the roles necessary for AWS lateral movement
Thanks to Arnaud PETITCOL (Wavestone), AWS Master
======================================
*/

# Create a role "dest_iam_ro_role" with IAM RO that could be assumed by any role from the SRC account

resource "aws_iam_role" "dest_iam_ro_role" {
  provider           = aws.dest
  name               = "${var.dest_iam_ro_role_name}"
  assume_role_policy = data.aws_iam_policy_document.dest_iam_ro_role_trusted_policy_doc.json
}

data "aws_iam_policy_document" "dest_iam_ro_role_trusted_policy_doc" {
  provider           = aws.dest
  statement {
    sid        = ""
    effect     = "Allow"
    actions    = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.src.account_id]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dest_ro_role_iam_policy_attachment" {
  provider   = aws.dest
  role       = aws_iam_role.dest_iam_ro_role.name
  policy_arn = aws_iam_policy.dest_custom_iam_ro_iam_policy.arn
}

data "aws_iam_policy_document" "dest_custom_iam_ro_iam_policy_doc" {
  provider           = aws.dest
  statement {
    sid        = ""
    effect     = "Allow"
    actions    = ["iam:Get*","iam:List*"]
    resources  = [
        "arn:aws:iam::${data.aws_caller_identity.dest.account_id}:role/*",
        "arn:aws:iam::${data.aws_caller_identity.dest.account_id}:policy/*"
      ]
  }
}

resource "aws_iam_policy" "dest_custom_iam_ro_iam_policy" {
  provider    = aws.dest
  name        = "dest_custom_iam_ro_iam_policy"
  description = "Allow to use specific IAM actions"
  policy = data.aws_iam_policy_document.dest_custom_iam_ro_iam_policy_doc.json
}

# Create an IAM role "dest_admin_role" that could be assumed by the SRC account "src_lambda_to_admin_master_role_name"

resource "aws_iam_role" "dest_admin_role" {
  provider = aws.dest
  name     = "${var.dest_admin_role_name}"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "AWS": "arn:aws:iam::${data.aws_caller_identity.src.account_id}:role/${var.src_lambda_to_admin_master_role_name}"
    },
    "Effect": "Allow",
    "Sid": ""
  }
]
}
EOF
}

# Affect S3, SSM & IAM RO policy to dest_admin_role

resource "aws_iam_role_policy_attachment" "dest_admin_role_iam_policy_attachment" {
  provider   = aws.dest
  role       = aws_iam_role.dest_admin_role.name
  policy_arn = aws_iam_policy.dest_custom_iam_ro_iam_policy.arn
}
resource "aws_iam_role_policy_attachment" "dest_admin_role_s3_policy_attachment" {
  provider   = aws.dest
  role       = aws_iam_role.dest_admin_role.name
  policy_arn = aws_iam_policy.dest_custom_s3_ro_iam_policy.arn
}
resource "aws_iam_role_policy_attachment" "dest_admin_role_SSM_policy_attachment" {
  provider   = aws.dest
  role       = aws_iam_role.dest_admin_role.name
  policy_arn = aws_iam_policy.dest_custom_ssmSendCommand_iam_policy.arn
}

# Custom policy to access S3 flag in DEST

data "aws_iam_policy_document" "dest_custom_s3_ro_iam_policy_doc" {
  provider           = aws.dest
  statement {
    sid        = "CustomS3Policy"
    effect     = "Allow"
    actions    = ["s3:Get*", "s3:List*"]
    resources  = [aws_s3_bucket.dest_flag_bucket.arn, "*"]
  }
}

resource "aws_iam_policy" "dest_custom_s3_ro_iam_policy" {
  provider    = aws.dest
  name        = "custom_s3_ro_iam_policy"
  description = "Allow to access sensitive S3"
  policy = data.aws_iam_policy_document.dest_custom_s3_ro_iam_policy_doc.json
}

# Custom policy to execute code thanks to SendCommand on any EC2 in DST

data "aws_iam_policy_document" "dest_custom_ssmSendCommand_iam_policy_doc" {
  provider           = aws.dest
  statement {
    sid        = "CustomSSMPolicy"
    effect     = "Allow"
    actions    = ["ec2:DescribeInstances", "ssm:listCommands","ssm:listCommandInvocations","ssm:sendCommand"]
    resources  = ["*"]
  }
}

resource "aws_iam_policy" "dest_custom_ssmSendCommand_iam_policy" {
  provider           = aws.dest
  name        = "ssmSendCommand_policy"
  description = "Execute commands on any instance that supports SSM"
  policy = data.aws_iam_policy_document.dest_custom_ssmSendCommand_iam_policy_doc.json
}
