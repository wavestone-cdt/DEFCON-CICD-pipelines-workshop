data "aws_availability_zones" "available" {
  state = "available"
}

# Create the VPC dedicated to the Lab
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.name}_vpc"
  cidr = var.cidr_block

  # List of subnets to be created
  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets


  # Activate auto-mapping of public IP on public subnets
  map_public_ip_on_launch = true

  # Create an Internet gateway for public subnets
  create_igw = true

  # Use NAT gateway for private subnets (single nat within the first public subnet)
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Disable VPC flow log
  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

}

# Create network ACL within the VPC to prevent communications between labs
resource "aws_network_acl" "lab_acl" {
  # One ACL per lab
  count  = length(local.lab_subnets)
  vpc_id = module.vpc.vpc_id

  # Select all subnets in the lab
  subnet_ids = concat(
    [for v in local.public_lab_subnets[count.index]: element(module.vpc.public_subnets, index(local.public_subnets, v))],
    [for v in local.private_lab_subnets[count.index]: element(module.vpc.private_subnets, index(local.private_subnets, v))],
  )

  # Allow egress & ingress to/from common networkrs, the same lab and Internet
  # For internet access, need to allow 0.0.0.0/0 but deny the VPC network
  # Allow egress to common networks and to networs of the same lab
  #
  # EGRESS
  egress {
    rule_no    = 100
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = local.common_cidr_block
    action     = "allow"
  }
  egress {
    rule_no    = 200
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = local.lab_subnets[count.index]
    action     = "allow"
  }
  egress {
    rule_no    = 300
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = var.cidr_block
    action     = "deny"
  }
  egress {
    rule_no    = 400
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # INGRESS
  ingress {
    rule_no    = 100
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = local.common_cidr_block
    action     = "allow"
  }
  ingress {
    rule_no    = 200
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = local.lab_subnets[count.index]
    action     = "allow"
  }
  ingress {
    rule_no    = 300
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = var.cidr_block
    action     = "deny"
  }
  ingress {
    rule_no    = 400
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = {
    Name = "${ var.name }-ACL-Lab-${ count.index }"
  }
}
