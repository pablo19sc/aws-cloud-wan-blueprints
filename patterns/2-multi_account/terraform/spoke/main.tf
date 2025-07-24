/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/2-multi_account/terraform/spoke/main.tf ---

# ---------- RAM SHARE ACCEPTANCE ----------
# Accepting resource share from Networking Account
resource "aws_ram_resource_share_accepter" "accept_networking_share" {
  provider = aws.awsnvirginia

  share_arn = var.resource_share_arn
}

# Local variable - obtaining Core Network ARN from resource share
locals {
  core_network_arn = aws_ram_resource_share_accepter.accept_networking_share.resources[0]
}

# ---------- RESOURCES IN IRELAND ----------
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  for_each  = var.ireland_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.5.0"
  providers = { aws = aws.awsireland }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = split("/", local.core_network_arn)[1]
    arn = local.core_network_arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints = { netmask = each.value.endpoint_subnet_netmask }
    workload  = { netmask = each.value.workload_subnet_netmask }
    core_network = {
      netmask            = each.value.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = each.value.segment
      }
    }
  }
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "ireland_compute" {
  for_each  = module.ireland_spoke_vpcs
  source    = "../../../tf_modules/compute"
  providers = { aws = aws.awsireland }

  identifier      = var.identifier
  vpc_name        = each.key
  vpc             = each.value
  vpc_information = var.ireland_spoke_vpcs[each.key]
}

# ---------- RESOURCES IN N. VIRGINIA ----------
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  for_each  = var.nvirginia_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.5.0"
  providers = { aws = aws.awsnvirginia }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = split("/", local.core_network_arn)[1]
    arn = local.core_network_arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints = { netmask = each.value.endpoint_subnet_netmask }
    workload  = { netmask = each.value.workload_subnet_netmask }
    core_network = {
      netmask            = each.value.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = each.value.segment
      }
    }
  }
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "nvirginia_compute" {
  for_each  = module.nvirginia_spoke_vpcs
  source    = "../../../tf_modules/compute"
  providers = { aws = aws.awsnvirginia }

  identifier      = var.identifier
  vpc_name        = each.key
  vpc             = each.value
  vpc_information = var.nvirginia_spoke_vpcs[each.key]
}
