/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/3-traffic_inspection/5-spoke_vpcs_tgw/terraform/main.tf ---

# ---------- AWS CLOUD WAN RESOURCES ----------
# Global Network
resource "awscc_networkmanager_global_network" "global_network" {
  provider = awscc.awsccoregon

  description = "Global Network - ${var.identifier}"

  tags = [{
    key   = "Name"
    value = "Global Network - ${var.identifier}"
  }]
}

# Core Network
resource "awscc_networkmanager_core_network" "core_network" {
  provider = awscc.awsccoregon

  global_network_id = awscc_networkmanager_global_network.global_network.id
  description       = "Core Network - ${var.identifier}"

  policy_document = data.aws_networkmanager_core_network_policy_document.policy.json

  tags = [{
    key   = "Name"
    value = "Core Network - ${var.identifier}"
  }]
}

# ---------- RESOURCES IN IRELAND ----------
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  for_each  = var.ireland_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "4.5.0"
  providers = { aws = aws.awsireland }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints       = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.cnetwork_subnet_netmask }
  }
}

# Inspection VPC (attached to Transit Gateway)
module "ireland_tgw_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "4.5.0"
  providers = { aws = aws.awsireland }

  name       = "inspection-vpc-tgw-ireland"
  cidr_block = var.inspection_vpc.cidr_block
  az_count   = var.inspection_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id
  transit_gateway_routes = {
    endpoints = "10.0.0.0/16"
  }

  subnets = {
    public = {
      netmask                   = var.inspection_vpc.public_subnet_netmask
      nat_gateway_configuration = "all_azs"
    }
    endpoints = {
      netmask                 = var.inspection_vpc.public_subnet_netmask
      connect_to_public_natgw = true
    }
    transit_gateway = {
      netmask                                = var.inspection_vpc.cnetwork_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

# AWS Network Firewall resource
module "ireland_networkfirewall" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsireland }

  network_firewall_name        = "ireland-anfw-${var.identifier}"
  network_firewall_description = "AWS Network Firewall - Ireland"
  network_firewall_policy      = module.ireland_anfw_policy.policy_arn

  vpc_id      = module.ireland_tgw_inspection_vpc.vpc_attributes.id
  number_azs  = var.inspection_vpc.number_azs
  vpc_subnets = { for k, v in module.ireland_tgw_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }

  routing_configuration = {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = { for k, v in module.ireland_tgw_inspection_vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
      public_subnet_route_tables       = { for k, v in module.ireland_tgw_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks              = ["10.0.0.0/16"]
    }
  }
}

# AWS Network Firewall policy
module "ireland_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsireland }

  identifier   = var.identifier
  traffic_flow = "all"
}

# AWS Transit Gateway and TGW route tables
resource "aws_ec2_transit_gateway" "ireland_tgw" {
  provider = aws.awsireland

  amazon_side_asn                 = var.asn.ireland
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Transit Gateway - Ireland"

  tags = {
    Name = "tgw-ireland-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ireland_tgw_rt_production" {
  provider = aws.awsireland

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id

  tags = {
    Name = "production-rt-ireland-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ireland_tgw_rt_production_routes" {
  provider = aws.awsireland

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id

  tags = {
    Name = "production-routes-rt-ireland-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ireland_tgw_rt_development" {
  provider = aws.awsireland

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id

  tags = {
    Name = "development-rt-ireland-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ireland_tgw_rt_postinspection" {
  provider = aws.awsireland

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id

  tags = {
    Name = "postinspection-rt-ireland-${var.identifier}"
  }
}

# AWS Transit Gateway associations
resource "aws_ec2_transit_gateway_route_table_association" "ireland_tgw_associations" {
  provider = aws.awsireland
  for_each = var.ireland_spoke_vpcs

  transit_gateway_attachment_id  = module.ireland_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.segment == "production" ? aws_ec2_transit_gateway_route_table.ireland_tgw_rt_production.id : aws_ec2_transit_gateway_route_table.ireland_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_association" "ireland_tgw_inspection_association" {
  provider = aws.awsireland

  transit_gateway_attachment_id  = module.ireland_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_postinspection.id
}

# AWS Transit Gateway routing
# 1. Development attachments propagating to development route table.
# 2. All attachments propagating to post-inspection route table
# 3. Default route in production and development to Inspection VPC
# 4. Production attachments propagating to production-routes route table
resource "aws_ec2_transit_gateway_route_table_propagation" "ireland_development_propagation" {
  provider = aws.awsireland
  for_each = { for k, v in var.ireland_spoke_vpcs : k => v if v.segment == "development" }

  transit_gateway_attachment_id  = module.ireland_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ireland_postinspection_propagation" {
  provider = aws.awsireland
  for_each = var.ireland_spoke_vpcs

  transit_gateway_attachment_id  = module.ireland_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_postinspection.id
}

resource "aws_ec2_transit_gateway_route" "ireland_tgw_default_production" {
  provider = aws.awsireland

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.ireland_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_production.id
}

resource "aws_ec2_transit_gateway_route" "ireland_tgw_default_development" {
  provider = aws.awsireland

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.ireland_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ireland_production_propagation" {
  provider = aws.awsireland
  for_each = { for k, v in var.ireland_spoke_vpcs : k => v if v.segment == "production" }

  transit_gateway_attachment_id  = module.ireland_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_production_routes.id
}

# Inspection VPC (attached to Cloud WAN)
module "ireland_cwan_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.4.0"
  providers = { aws = aws.awsireland }

  core_network_arn = awscc_networkmanager_core_network.core_network.core_network_arn

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "inspection-vpc-ireland"
      cidr_block = var.inspection_vpc.cidr_block
      az_count   = var.inspection_vpc.number_azs

      subnets = {
        endpoints = { netmask = var.inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.inspection_vpc.cnetwork_subnet_netmask

          tags = { inspection = "true" }
        }
      }
    }
  }
}

# Local variable to create the subnet mapping in Cloud WAN's Inspection VPC (for multi-VPC endpoint)
locals {
  ireland_availability_zones = module.ireland_cwan_inspection_vpc.central_vpcs.inspection.azs
}

# Network Firewall VPC endpoints in Cloud WAN's Inspection VPC - resource created in Cloud WAN module
resource "awscc_networkfirewall_vpc_endpoint_association" "ireland_firewallendpoint_association" {
  count    = var.inspection_vpc.number_azs
  provider = awscc.awsccireland

  description  = "Cloud WAN VPC endpoints - Ireland"
  firewall_arn = module.ireland_networkfirewall.aws_network_firewall.arn
  vpc_id       = module.ireland_cwan_inspection_vpc.central_vpcs["inspection"].vpc_attributes.id

  subnet_mapping = {
    subnet_id = { for k, v in module.ireland_cwan_inspection_vpc.central_vpcs.inspection.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }[local.ireland_availability_zones[count.index]]
  }
}

# VPC routes: Core network subnet to VPC endpoints --> 0.0.0.0/0
resource "aws_route" "ireland_inspectionvpc_cwan_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsireland

  route_table_id         = module.ireland_cwan_inspection_vpc.central_vpcs["inspection"].rt_attributes_by_type_by_az.core_network[local.ireland_availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.ireland_firewallendpoint_association[count.index].endpoint_id
}

# AWS Cloud WAN - Transit Gateway peering
# 1. Transit Gateway policy table
# 2. Peering and policy table association
# 3. TGW RT attachment (production and development)
resource "aws_ec2_transit_gateway_policy_table" "ireland_tgw_policy_table" {
  provider = aws.awsireland

  transit_gateway_id = aws_ec2_transit_gateway.ireland_tgw.id

  tags = {
    Name = "TGW Policy Table - Ireland"
  }
}

resource "aws_networkmanager_transit_gateway_peering" "ireland_peering" {
  provider = aws.awsireland

  core_network_id     = awscc_networkmanager_core_network.core_network.core_network_id
  transit_gateway_arn = aws_ec2_transit_gateway.ireland_tgw.arn
}

resource "aws_ec2_transit_gateway_policy_table_association" "ireland_policytable_association" {
  provider = aws.awsireland

  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.ireland_peering.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.ireland_tgw_policy_table.id
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "ireland_tgw_rt_attachment_production" {
  provider = aws.awsireland

  peering_id                      = aws_networkmanager_transit_gateway_peering.ireland_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_production.arn

  tags = {
    domain = "production"
  }
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "ireland_tgw_rt_attachment_production_routes" {
  provider = aws.awsireland

  peering_id                      = aws_networkmanager_transit_gateway_peering.ireland_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_production_routes.arn

  tags = {
    domain = "production"
  }
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "ireland_tgw_rt_attachment_development" {
  provider = aws.awsireland

  peering_id                      = aws_networkmanager_transit_gateway_peering.ireland_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.ireland_tgw_rt_development.arn

  tags = {
    domain = "development"
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
  version   = "4.5.0"
  providers = { aws = aws.awsnvirginia }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints       = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.cnetwork_subnet_netmask }
  }
}

# Inspection VPC (attached to Transit Gateway)
module "nvirginia_tgw_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "4.5.0"
  providers = { aws = aws.awsnvirginia }

  name       = "inspection-vpc-tgw-nvirginia"
  cidr_block = var.inspection_vpc.cidr_block
  az_count   = var.inspection_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id
  transit_gateway_routes = {
    endpoints = "10.0.0.0/16"
  }

  subnets = {
    public = {
      netmask                   = var.inspection_vpc.public_subnet_netmask
      nat_gateway_configuration = "all_azs"
    }
    endpoints = {
      netmask                 = var.inspection_vpc.public_subnet_netmask
      connect_to_public_natgw = true
    }
    transit_gateway = {
      netmask                                = var.inspection_vpc.cnetwork_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

# AWS Network Firewall resource
module "nvirginia_networkfirewall" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsnvirginia }

  network_firewall_name        = "nvirginia-anfw-${var.identifier}"
  network_firewall_description = "AWS Network Firewall - N. Virginia"
  network_firewall_policy      = module.nvirginia_anfw_policy.policy_arn

  vpc_id      = module.nvirginia_tgw_inspection_vpc.vpc_attributes.id
  number_azs  = var.inspection_vpc.number_azs
  vpc_subnets = { for k, v in module.nvirginia_tgw_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }

  routing_configuration = {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = { for k, v in module.nvirginia_tgw_inspection_vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
      public_subnet_route_tables       = { for k, v in module.nvirginia_tgw_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks              = ["10.0.0.0/16"]
    }
  }
}

# AWS Network Firewall policy
module "nvirginia_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsnvirginia }

  identifier   = var.identifier
  traffic_flow = "all"
}

# AWS Transit Gateway and TGW route tables
resource "aws_ec2_transit_gateway" "nvirginia_tgw" {
  provider = aws.awsnvirginia

  amazon_side_asn                 = var.asn.nvirginia
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Transit Gateway - N. Virginia"

  tags = {
    Name = "tgw-nvirginia-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "nvirginia_tgw_rt_production" {
  provider = aws.awsnvirginia

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id

  tags = {
    Name = "production-rt-nvirginia-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "nvirginia_tgw_rt_production_routes" {
  provider = aws.awsnvirginia

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id

  tags = {
    Name = "production-routes-rt-nvirginia-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "nvirginia_tgw_rt_development" {
  provider = aws.awsnvirginia

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id

  tags = {
    Name = "development-rt-nvirginia-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "nvirginia_tgw_rt_postinspection" {
  provider = aws.awsnvirginia

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id

  tags = {
    Name = "postinspection-rt-nvirginia-${var.identifier}"
  }
}

# AWS Transit Gateway associations
resource "aws_ec2_transit_gateway_route_table_association" "nvirginia_tgw_associations" {
  provider = aws.awsnvirginia
  for_each = var.nvirginia_spoke_vpcs

  transit_gateway_attachment_id  = module.nvirginia_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.segment == "production" ? aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_production.id : aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_association" "nvirginia_tgw_inspection_association" {
  provider = aws.awsnvirginia

  transit_gateway_attachment_id  = module.nvirginia_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_postinspection.id
}

# AWS Transit Gateway routing
# 1. Development attachments propagating to development route table
# 2. All attachments propagating to post-inspection route table
# 3. Default route in production and development to Inspection VPC
# 4. Production attachments propagating to production-routes route table
resource "aws_ec2_transit_gateway_route_table_propagation" "nvirginia_development_propagation" {
  provider = aws.awsnvirginia
  for_each = { for k, v in var.nvirginia_spoke_vpcs : k => v if v.segment == "development" }

  transit_gateway_attachment_id  = module.nvirginia_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "nvirginia_postinspection_propagation" {
  provider = aws.awsnvirginia
  for_each = var.nvirginia_spoke_vpcs

  transit_gateway_attachment_id  = module.nvirginia_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_postinspection.id
}

resource "aws_ec2_transit_gateway_route" "nvirginia_tgw_default_production" {
  provider = aws.awsnvirginia

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.nvirginia_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_production.id
}

resource "aws_ec2_transit_gateway_route" "nvirginia_tgw_default_development" {
  provider = aws.awsnvirginia

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.nvirginia_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "nvirginia_production_propagation" {
  provider = aws.awsnvirginia
  for_each = { for k, v in var.nvirginia_spoke_vpcs : k => v if v.segment == "production" }

  transit_gateway_attachment_id  = module.nvirginia_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_production_routes.id
}

# Inspection VPC (attached to Cloud WAN)
module "nvirginia_cwan_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.4.0"
  providers = { aws = aws.awsnvirginia }

  core_network_arn = awscc_networkmanager_core_network.core_network.core_network_arn

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "inspection-vpc-ireland"
      cidr_block = var.inspection_vpc.cidr_block
      az_count   = var.inspection_vpc.number_azs

      subnets = {
        endpoints = { netmask = var.inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.inspection_vpc.cnetwork_subnet_netmask

          tags = { inspection = "true" }
        }
      }
    }
  }
}

# Local variable to create the subnet mapping in Cloud WAN's Inspection VPC (for multi-VPC endpoint)
locals {
  nvirginia_availability_zones = module.nvirginia_cwan_inspection_vpc.central_vpcs.inspection.azs
}

# Network Firewall VPC endpoints in Cloud WAN's Inspection VPC - resource created in Cloud WAN module
resource "awscc_networkfirewall_vpc_endpoint_association" "nvirginia_firewallendpoint_association" {
  count    = var.inspection_vpc.number_azs
  provider = awscc.awsccnvirginia

  description  = "Cloud WAN VPC endpoints - N. Virginia"
  firewall_arn = module.nvirginia_networkfirewall.aws_network_firewall.arn
  vpc_id       = module.nvirginia_cwan_inspection_vpc.central_vpcs["inspection"].vpc_attributes.id

  subnet_mapping = {
    subnet_id = { for k, v in module.nvirginia_cwan_inspection_vpc.central_vpcs.inspection.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }[local.nvirginia_availability_zones[count.index]]
  }
}

# VPC routes: Core network subnet to VPC endpoints --> 0.0.0.0/0
resource "aws_route" "nvirginia_inspectionvpc_cwan_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsnvirginia

  route_table_id         = module.nvirginia_cwan_inspection_vpc.central_vpcs["inspection"].rt_attributes_by_type_by_az.core_network[local.nvirginia_availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.nvirginia_firewallendpoint_association[count.index].endpoint_id
}

# AWS Cloud WAN - Transit Gateway peering
# 1. Transit Gateway policy table
# 2. Peering and policy table association
# 3. TGW RT attachment (production and development)
resource "aws_ec2_transit_gateway_policy_table" "nvirginia_tgw_policy_table" {
  provider = aws.awsnvirginia

  transit_gateway_id = aws_ec2_transit_gateway.nvirginia_tgw.id

  tags = {
    Name = "TGW Policy Table - N. Virginia"
  }
}

resource "aws_networkmanager_transit_gateway_peering" "nvirginia_peering" {
  provider = aws.awsnvirginia

  core_network_id     = awscc_networkmanager_core_network.core_network.core_network_id
  transit_gateway_arn = aws_ec2_transit_gateway.nvirginia_tgw.arn
}

resource "aws_ec2_transit_gateway_policy_table_association" "nvirginia_policytable_association" {
  provider = aws.awsnvirginia

  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.nvirginia_peering.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.nvirginia_tgw_policy_table.id
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "nvirginia_tgw_rt_attachment_production" {
  provider = aws.awsnvirginia

  peering_id                      = aws_networkmanager_transit_gateway_peering.nvirginia_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_production.arn

  tags = {
    domain = "production"
  }
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "nvirginia_tgw_rt_attachment_production_routes" {
  provider = aws.awsnvirginia

  peering_id                      = aws_networkmanager_transit_gateway_peering.nvirginia_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_production_routes.arn

  tags = {
    domain = "production"
  }
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "nvirginia_tgw_rt_attachment_development" {
  provider = aws.awsnvirginia

  peering_id                      = aws_networkmanager_transit_gateway_peering.nvirginia_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.nvirginia_tgw_rt_development.arn

  tags = {
    domain = "development"
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

# ---------- RESOURCES IN OREGON ----------
# Spoke VPCs - definition in variables.tf
module "oregon_spoke_vpcs" {
  for_each  = var.oregon_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "4.5.0"
  providers = { aws = aws.awsoregon }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints       = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.cnetwork_subnet_netmask }
  }
}

# Inspection VPC (attached to Transit Gateway)
module "oregon_tgw_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "4.5.0"
  providers = { aws = aws.awsoregon }

  name       = "inspection-vpc-tgw-oregon"
  cidr_block = var.inspection_vpc.cidr_block
  az_count   = var.inspection_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id
  transit_gateway_routes = {
    endpoints = "10.0.0.0/16"
  }

  subnets = {
    public = {
      netmask                   = var.inspection_vpc.public_subnet_netmask
      nat_gateway_configuration = "all_azs"
    }
    endpoints = {
      netmask                 = var.inspection_vpc.public_subnet_netmask
      connect_to_public_natgw = true
    }
    transit_gateway = {
      netmask                                = var.inspection_vpc.cnetwork_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

# AWS Network Firewall resource
module "oregon_networkfirewall" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsoregon }

  network_firewall_name        = "oregon-anfw-${var.identifier}"
  network_firewall_description = "AWS Network Firewall - Oregon"
  network_firewall_policy      = module.oregon_anfw_policy.policy_arn

  vpc_id      = module.oregon_tgw_inspection_vpc.vpc_attributes.id
  number_azs  = var.inspection_vpc.number_azs
  vpc_subnets = { for k, v in module.oregon_tgw_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }

  routing_configuration = {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = { for k, v in module.oregon_tgw_inspection_vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
      public_subnet_route_tables       = { for k, v in module.oregon_tgw_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks              = ["10.0.0.0/16"]
    }
  }
}

# AWS Network Firewall policy
module "oregon_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsoregon }

  identifier   = var.identifier
  traffic_flow = "all"
}

# AWS Transit Gateway and TGW route tables
resource "aws_ec2_transit_gateway" "oregon_tgw" {
  provider = aws.awsoregon

  amazon_side_asn                 = var.asn.oregon
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Transit Gateway - Oregon"

  tags = {
    Name = "tgw-oregon-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "oregon_tgw_rt_production" {
  provider = aws.awsoregon

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

  tags = {
    Name = "production-rt-oregon-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "oregon_tgw_rt_production_routes" {
  provider = aws.awsoregon

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

  tags = {
    Name = "production-routes-rt-oregon-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "oregon_tgw_rt_development" {
  provider = aws.awsoregon

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

  tags = {
    Name = "development-rt-oregon-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "oregon_tgw_rt_postinspection" {
  provider = aws.awsoregon

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

  tags = {
    Name = "postinspection-rt-oregon-${var.identifier}"
  }
}

# AWS Transit Gateway associations
resource "aws_ec2_transit_gateway_route_table_association" "oregon_tgw_associations" {
  provider = aws.awsoregon
  for_each = var.oregon_spoke_vpcs

  transit_gateway_attachment_id  = module.oregon_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.segment == "production" ? aws_ec2_transit_gateway_route_table.oregon_tgw_rt_production.id : aws_ec2_transit_gateway_route_table.oregon_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_association" "oregon_tgw_inspection_association" {
  provider = aws.awsoregon

  transit_gateway_attachment_id  = module.oregon_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_postinspection.id
}

# AWS Transit Gateway routing
# 1. Development attachments propagating to development route table
# 2. All attachments propagating to post-inspection route table
# 3. Default route in production and development to Inspection VPC
# 4. Production attachments propagating to production-routes route table
resource "aws_ec2_transit_gateway_route_table_propagation" "oregon_development_propagation" {
  provider = aws.awsoregon
  for_each = { for k, v in var.oregon_spoke_vpcs : k => v if v.segment == "development" }

  transit_gateway_attachment_id  = module.oregon_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "oregon_postinspection_propagation" {
  provider = aws.awsoregon
  for_each = var.oregon_spoke_vpcs

  transit_gateway_attachment_id  = module.oregon_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_postinspection.id
}

resource "aws_ec2_transit_gateway_route" "oregon_tgw_default_production" {
  provider = aws.awsoregon

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.oregon_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_production.id
}

resource "aws_ec2_transit_gateway_route" "oregon_tgw_default_development" {
  provider = aws.awsoregon

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.oregon_tgw_inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_development.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "oregon_production_propagation" {
  provider = aws.awsoregon
  for_each = { for k, v in var.oregon_spoke_vpcs : k => v if v.segment == "production" }

  transit_gateway_attachment_id  = module.oregon_spoke_vpcs[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_production_routes.id
}

# Inspection VPC (attached to Cloud WAN)
module "oregon_cwan_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.4.0"
  providers = { aws = aws.awsoregon }

  core_network_arn = awscc_networkmanager_core_network.core_network.core_network_arn

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "inspection-vpc-oregon"
      cidr_block = var.inspection_vpc.cidr_block
      az_count   = var.inspection_vpc.number_azs

      subnets = {
        endpoints = { netmask = var.inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.inspection_vpc.cnetwork_subnet_netmask

          tags = { inspection = "true" }
        }
      }
    }
  }
}

# Local variable to create the subnet mapping in Cloud WAN's Inspection VPC (for multi-VPC endpoint)
locals {
  oregon_availability_zones = module.oregon_cwan_inspection_vpc.central_vpcs.inspection.azs
}

# Network Firewall VPC endpoints in Cloud WAN's Inspection VPC - resource created in Cloud WAN module
resource "awscc_networkfirewall_vpc_endpoint_association" "oregon_firewallendpoint_association" {
  count    = var.inspection_vpc.number_azs
  provider = awscc.awsccoregon

  description  = "Cloud WAN VPC endpoints - Oregon"
  firewall_arn = module.oregon_networkfirewall.aws_network_firewall.arn
  vpc_id       = module.oregon_cwan_inspection_vpc.central_vpcs["inspection"].vpc_attributes.id

  subnet_mapping = {
    subnet_id = { for k, v in module.oregon_cwan_inspection_vpc.central_vpcs.inspection.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }[local.oregon_availability_zones[count.index]]
  }
}

# VPC routes: Core network subnet to VPC endpoints --> 0.0.0.0/0
resource "aws_route" "oregon_inspectionvpc_cwan_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsoregon

  route_table_id         = module.oregon_cwan_inspection_vpc.central_vpcs["inspection"].rt_attributes_by_type_by_az.core_network[local.oregon_availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.oregon_firewallendpoint_association[count.index].endpoint_id
}

# AWS Cloud WAN - Transit Gateway peering
# 1. Transit Gateway policy table
# 2. Peering and policy table association
# 3. TGW RT attachment (production and development)
resource "aws_ec2_transit_gateway_policy_table" "oregon_tgw_policy_table" {
  provider = aws.awsoregon

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

  tags = {
    Name = "TGW Policy Table - Oregon"
  }
}

resource "aws_networkmanager_transit_gateway_peering" "oregon_peering" {
  provider = aws.awsnvirginia

  core_network_id     = awscc_networkmanager_core_network.core_network.core_network_id
  transit_gateway_arn = aws_ec2_transit_gateway.oregon_tgw.arn
}

resource "aws_ec2_transit_gateway_policy_table_association" "oregon_policytable_association" {
  provider = aws.awsoregon

  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.oregon_peering.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.oregon_tgw_policy_table.id
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "oregon_tgw_rt_attachment_production" {
  provider = aws.awsoregon

  peering_id                      = aws_networkmanager_transit_gateway_peering.oregon_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_production.arn

  tags = {
    domain = "production"
  }
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "oregon_tgw_rt_attachment_production_routes" {
  provider = aws.awsoregon

  peering_id                      = aws_networkmanager_transit_gateway_peering.oregon_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_production_routes.arn

  tags = {
    domain = "production"
  }
}

resource "aws_networkmanager_transit_gateway_route_table_attachment" "oregon_tgw_rt_attachment_development" {
  provider = aws.awsoregon

  peering_id                      = aws_networkmanager_transit_gateway_peering.oregon_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.oregon_tgw_rt_development.arn

  tags = {
    domain = "development"
  }
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "oregon_compute" {
  for_each  = module.oregon_spoke_vpcs
  source    = "../../../tf_modules/compute"
  providers = { aws = aws.awsoregon }

  identifier      = var.identifier
  vpc_name        = each.key
  vpc             = each.value
  vpc_information = var.oregon_spoke_vpcs[each.key]
}
