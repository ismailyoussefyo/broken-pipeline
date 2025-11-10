# VPC Configuration
# This file defines the networking layer: VPCs, subnets, peering, and Network ACLs

# Application VPC - CIDR 10.40.0.0/16
# Deployed in eu-central-1 with 4 subnets (2 public, 2 private)
module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-app-vpc"
  cidr = "10.40.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.40.1.0/24", "10.40.2.0/24"]
  public_subnets  = ["10.40.10.0/24", "10.40.20.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true  # Cost optimization: single NAT gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-app-vpc"
  }
}

# Jenkins VPC - CIDR 10.41.0.0/16
# Deployed in eu-central-1 with 4 subnets (2 public, 2 private)
module "jenkins_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-jenkins-vpc"
  cidr = "10.41.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.41.1.0/24", "10.41.2.0/24"]
  public_subnets  = ["10.41.10.0/24", "10.41.20.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true  # Cost optimization: single NAT gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-jenkins-vpc"
  }
}

# VPC Peering Connection
# Enables communication between Application VPC (10.40.0.0/16) and Jenkins VPC (10.41.0.0/16)
resource "aws_vpc_peering_connection" "app_jenkins" {
  vpc_id      = module.app_vpc.vpc_id
  peer_vpc_id = module.jenkins_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-vpc-peering"
  }
}

# Route table entries for VPC peering - App VPC Private Subnets
resource "aws_route" "app_to_jenkins" {
  route_table_id            = module.app_vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.41.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_jenkins.id
}

# Route table entries for VPC peering - App VPC Public Subnets
resource "aws_route" "app_public_to_jenkins" {
  route_table_id            = module.app_vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.41.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_jenkins.id
}

# Route table entries for VPC peering - Jenkins VPC Private Subnets
resource "aws_route" "jenkins_to_app" {
  route_table_id            = module.jenkins_vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.40.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_jenkins.id
}

# Route table entries for VPC peering - Jenkins VPC Public Subnets
resource "aws_route" "jenkins_public_to_app" {
  route_table_id            = module.jenkins_vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.40.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_jenkins.id
}

# Network ACLs - Application VPC Public Subnets
# Blocks non-HTTP/HTTPS inbound traffic, aligns with Security Groups
resource "aws_network_acl" "app_public" {
  vpc_id = module.app_vpc.vpc_id

  # Allow HTTP inbound (port 80)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow HTTPS inbound (port 443)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow ephemeral ports for return traffic
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Deny all other inbound (implicit deny, but explicit for clarity)
  ingress {
    rule_no    = 200
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  subnet_ids = module.app_vpc.public_subnets

  tags = {
    Name = "${var.project_name}-app-public-nacl"
  }
}

# Network ACLs - Application VPC Private Subnets
resource "aws_network_acl" "app_private" {
  vpc_id = module.app_vpc.vpc_id

  # Allow all inbound from VPC
  ingress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "10.40.0.0/16"
    action     = "allow"
  }

  # Allow inbound from Jenkins VPC
  ingress {
    rule_no    = 110
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "10.41.0.0/16"
    action     = "allow"
  }

  # CRITICAL FIX: Allow ephemeral ports for return traffic from internet (via NAT)
  # Required for Docker image pulls, package downloads, and any outbound connections
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  subnet_ids = module.app_vpc.private_subnets

  tags = {
    Name = "${var.project_name}-app-private-nacl"
  }
}

# Network ACLs - Jenkins VPC Public Subnets
# Blocks non-HTTP/HTTPS inbound traffic, aligns with Security Groups
resource "aws_network_acl" "jenkins_public" {
  vpc_id = module.jenkins_vpc.vpc_id

  # Allow HTTP inbound (port 80)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow HTTPS inbound (port 443) - restricted to Portugal IPs via Security Group and WAF
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow ephemeral ports for return traffic
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Deny all other inbound
  ingress {
    rule_no    = 200
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  subnet_ids = module.jenkins_vpc.public_subnets

  tags = {
    Name = "${var.project_name}-jenkins-public-nacl"
  }
}

# Network ACLs - Jenkins VPC Private Subnets
resource "aws_network_acl" "jenkins_private" {
  vpc_id = module.jenkins_vpc.vpc_id

  # Allow all inbound from VPC
  ingress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "10.41.0.0/16"
    action     = "allow"
  }

  # Allow inbound from App VPC
  ingress {
    rule_no    = 110
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "10.40.0.0/16"
    action     = "allow"
  }

  # CRITICAL FIX: Allow ephemeral ports for return traffic from internet (via NAT)
  # Required for Docker image pulls, package downloads, and any outbound connections
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  subnet_ids = module.jenkins_vpc.private_subnets

  tags = {
    Name = "${var.project_name}-jenkins-private-nacl"
  }
}
