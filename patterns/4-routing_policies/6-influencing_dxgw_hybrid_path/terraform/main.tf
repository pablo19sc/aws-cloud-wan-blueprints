/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/4-advanced_routing/6-influencing_dxgw_hybrid_path/terraform/main.tf ---

data "aws_caller_identity" "current" {}

# ---------- AWS CLOUD WAN RESOURCES ----------
# Global Network
resource "awscc_networkmanager_global_network" "global_network" {
  description = "Global Network - ${var.identifier}"

  tags = [{
    key   = "Name"
    value = "global-network-${var.identifier}"
  }]
}

# Core Network
resource "awscc_networkmanager_core_network" "core_network" {
  global_network_id = awscc_networkmanager_global_network.global_network.id
  description       = "Core Network - ${var.identifier}"

  policy_document = file("${path.module}/cloudwan_policy.json")

  tags = [{
    key   = "Name"
    value = "core-network-${var.identifier}"
  }]
}

# ---------- HYBRID RESOURCES (Direct Connect gateway) ----------
# Europe's Direct Connect gateway
resource "aws_dx_gateway" "europe_dxgw" {
  provider = aws.awsireland

  name            = "dxgw-europe"
  amazon_side_asn = var.dxgw_asns.europe
}

resource "aws_networkmanager_dx_gateway_attachment" "europe_dxgw_attachment" {
  provider = aws.awsireland

  core_network_id            = awscc_networkmanager_core_network.core_network.core_network_id
  direct_connect_gateway_arn = "arn:aws:directconnect::${data.aws_caller_identity.current.account_id}:dx-gateway/${aws_dx_gateway.europe_dxgw.id}"
  edge_locations             = values(var.aws_regions)
}

# US' Direct Connect gateway
resource "aws_dx_gateway" "us_dxgw" {
  provider = aws.awsnvirginia

  name            = "dxgw-us"
  amazon_side_asn = var.dxgw_asns.us
}

resource "aws_networkmanager_dx_gateway_attachment" "us_dxgw_attachment" {
  provider = aws.awsnvirginia

  core_network_id            = awscc_networkmanager_core_network.core_network.core_network_id
  direct_connect_gateway_arn = "arn:aws:directconnect::${data.aws_caller_identity.current.account_id}:dx-gateway/${aws_dx_gateway.us_dxgw.id}"
  edge_locations             = values(var.aws_regions)
}

# ---------- RESOURCES IN IRELAND ----------
# Spoke VPC - definition in variables.tf
module "ireland_spoke_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.7.3"
  providers = { aws = aws.awsireland }

  name       = var.ireland_spoke_vpc.name
  cidr_block = var.ireland_spoke_vpc.cidr_block
  az_count   = var.ireland_spoke_vpc.number_azs

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints    = { netmask = var.ireland_spoke_vpc.endpoint_subnet_netmask }
    workload     = { netmask = var.ireland_spoke_vpc.workload_subnet_netmask }
    core_network = { netmask = var.ireland_spoke_vpc.cnetwork_subnet_netmask }
  }
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "ireland_compute" {
  source    = "../../../tf_modules/compute"
  providers = { aws = aws.awsireland }

  identifier      = var.identifier
  vpc_name        = var.ireland_spoke_vpc.name
  vpc             = module.ireland_spoke_vpc
  vpc_information = var.ireland_spoke_vpc
}

# ---------- RESOURCES IN N. VIRGINIA ----------
# Spoke VPC - definition in variables.tf
module "nvirginia_spoke_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.7.3"
  providers = { aws = aws.awsnvirginia }

  name       = var.nvirginia_spoke_vpc.name
  cidr_block = var.nvirginia_spoke_vpc.cidr_block
  az_count   = var.nvirginia_spoke_vpc.number_azs

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints    = { netmask = var.nvirginia_spoke_vpc.endpoint_subnet_netmask }
    workload     = { netmask = var.nvirginia_spoke_vpc.workload_subnet_netmask }
    core_network = { netmask = var.nvirginia_spoke_vpc.cnetwork_subnet_netmask }
  }
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "nvirginia_compute" {
  source    = "../../../tf_modules/compute"
  providers = { aws = aws.awsnvirginia }

  identifier      = var.identifier
  vpc_name        = var.nvirginia_spoke_vpc.name
  vpc             = module.nvirginia_spoke_vpc
  vpc_information = var.nvirginia_spoke_vpc
}