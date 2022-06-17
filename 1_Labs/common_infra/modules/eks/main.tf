################################################################################
# Create the cluster
################################################################################
resource "aws_eks_cluster" "k8s" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    subnet_ids              = aws_subnet.k8s_cluster_subnet[*].id
  }
}

################################################################################
# Create the network
################################################################################
data "aws_availability_zones" "available" {}
# One subnet for each availability zone
resource "aws_subnet" "k8s_cluster_subnet" {
  count = var.cluster_availability_zones_num

  vpc_id            = var.cluster_vpc_id
  # split the cidr block for cluster subnets based on the number of subnet to
  # be created
  cidr_block        = cidrsubnet(var.cluster_subnet, ceil(log(var.cluster_availability_zones_num, 2)), count.index)
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  tags = (var.subnets_base_name != null
    ? {Name = "${ var.subnets_base_name }-cluster-net-${data.aws_availability_zones.available.names[count.index]}"}
    : {}
  )
}

resource "aws_subnet" "k8s_workers_subnet" {
    vpc_id     = var.cluster_vpc_id
    cidr_block = var.workers_subnet

    tags = (var.subnets_base_name != null
      ? {Name = "${ var.subnets_base_name }-workers-net"}
      : {}
    )
}

################################################################################
# Create the worker groups and nodes
################################################################################

resource "aws_eks_node_group" "k8s_workers_group" {
  cluster_name  = aws_eks_cluster.k8s.name
  node_role_arn = var.workers_role_arn
  subnet_ids    = [aws_subnet.k8s_workers_subnet.id]

  instance_types = [var.workers_instance_type]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }
}
