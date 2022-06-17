data "aws_caller_identity" "current" {}

/*
======================================
SRC: Create users for AWS lambda privesc
======================================
*/

resource "aws_iam_user" "user_perlab" {
  provider = aws.src
  name = "${ terraform.workspace }_user"
  path = "/"
}

resource "aws_iam_access_key" "user_perlab_key" {
  provider = aws.src
  user = aws_iam_user.user_perlab.name
}



resource "aws_iam_user" "ApplicationDeployment_user" {
  provider = aws.src
  name = "${ terraform.workspace }_ApplicationDeployment"
  path = "/"
}

resource "aws_iam_access_key" "ApplicationDeployment_user_key" {
  provider = aws.src
  user = aws_iam_user.ApplicationDeployment_user.name
}

resource "aws_iam_user_policy_attachment" "ApplicationDeployment_user_attach_policy_passrole" {
  provider   = aws.src
  user       = aws_iam_user.ApplicationDeployment_user.name
  policy_arn = local.ApplicationDeploymentPolicyArn
}

resource "aws_iam_user_policy_attachment" "ApplicationDeployment_user_attach_policy_iam_ro" {
  provider   = aws.src
  user       = aws_iam_user.ApplicationDeployment_user.name
  policy_arn = local.src_custom_iam_ro_src_iam_policyArn
}

/*
======================================
INFRA : Create users for kubernetes
======================================
*/

resource "aws_iam_user" "jenkins" {
  name = "${ local.name }-${ terraform.workspace }-business-app-jenkins"
  path = "/jenkins/"
}

resource "aws_iam_access_key" "jenkins" {
  user    = aws_iam_user.jenkins.name
}

resource "aws_iam_user" "k8s_monitoring" {
  name = "${ local.name }-${ terraform.workspace }-k8s-monitoring"
  path = "/k8s/"
}

resource "aws_iam_access_key" "k8s_monitoring" {
  user    = aws_iam_user.k8s_monitoring.name
}

// Policy to be able to update-kubeconfig with the users accounts
resource "aws_iam_policy" "eks_read" {
  name        = "${ local.name }-${ terraform.workspace }-eks-describe"
  path        = "/k8s/"
  description = "Allows to describe the cluster to update kube config"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = [module.eks.cluster_arn]
      },
    ]
  })
}
resource "aws_iam_user_policy_attachment" "eks_read_jenkins" {
  user       = aws_iam_user.jenkins.name
  policy_arn = aws_iam_policy.eks_read.arn
}
resource "aws_iam_user_policy_attachment" "eks_read_k8s_monitoring" {
  user       = aws_iam_user.k8s_monitoring.name
  policy_arn = aws_iam_policy.eks_read.arn
}
