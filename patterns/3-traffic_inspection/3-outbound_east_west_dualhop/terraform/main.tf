/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/3-traffic_inspection/3-outbound_east_west_dualhop/terraform/main.tf ---

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

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
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

# Inspection VPC - definition in variables.tf
module "ireland_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.4.0"
  providers = { aws = aws.awsireland }

  core_network_arn        = awscc_networkmanager_core_network.core_network.core_network_arn
  ipv4_network_definition = "10.0.0.0/16"

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

    outbound = {
      type       = "egress_with_inspection"
      name       = "outbound-vpc-ireland"
      cidr_block = var.inspection_vpc.cidr_block
      az_count   = var.inspection_vpc.number_azs

      subnets = {
        public    = { netmask = var.inspection_vpc.public_subnet_netmask }
        endpoints = { netmask = var.inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.inspection_vpc.cnetwork_subnet_netmask

          tags = { outbound = "true" }
        }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-ireland"
      description = "AWS Network Firewall - eu-west-1"
      policy_arn  = module.ireland_anfw_policy.policy_arn
    }
  }
}

# Local variable to create the subnet mapping in Outbound VPC (for multi-VPC endpoint)
locals {
  ireland_availability_zones = module.ireland_inspection_vpc.central_vpcs.outbound.azs
}

# Network Firewall VPC endpoints in Outbound VPC - resource created in Cloud WAN module
resource "awscc_networkfirewall_vpc_endpoint_association" "ireland_outbound_firewallendpoints" {
  count    = var.inspection_vpc.number_azs
  provider = awscc.awsccireland

  description  = "Outbound VPC endpoints - Ireland"
  firewall_arn = module.ireland_inspection_vpc.aws_network_firewall["inspection"].arn
  vpc_id       = module.ireland_inspection_vpc.central_vpcs["outbound"].vpc_attributes.id

  subnet_mapping = {
    subnet_id = { for k, v in module.ireland_inspection_vpc.central_vpcs.outbound.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }[local.ireland_availability_zones[count.index]]
  }
}

# VPC routes pointing to the VPC endpoints created by awscc_networkfirewall_vpc_endpoint_association
# 1. From core network subnet to VPC endpoints --> 0.0.0.0/0
# 2. From public subnets to VPC endpoints --> regional supernet
resource "aws_route" "ireland_outboundvpc_cwan_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsireland

  route_table_id         = module.ireland_inspection_vpc.central_vpcs["outbound"].rt_attributes_by_type_by_az.core_network[local.ireland_availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.ireland_outbound_firewallendpoints[count.index].endpoint_id
}

resource "aws_route" "ireland_outboundvpc_public_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsireland

  route_table_id         = module.ireland_inspection_vpc.central_vpcs["outbound"].rt_attributes_by_type_by_az.public[local.ireland_availability_zones[count.index]].id
  destination_cidr_block = "10.0.0.0/16"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.ireland_outbound_firewallendpoints[count.index].endpoint_id
}

# AWS Network Firewall policy
module "ireland_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsireland }

  identifier   = var.identifier
  traffic_flow = "all"
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

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
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

# Inspection VPC - definition in variables.tf
module "nvirginia_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.4.0"
  providers = { aws = aws.awsnvirginia }

  core_network_arn        = awscc_networkmanager_core_network.core_network.core_network_arn
  ipv4_network_definition = "10.10.0.0/16"

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "inspection-vpc-nvirginia"
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

    outbound = {
      type       = "egress_with_inspection"
      name       = "outbound-vpc-nvirginia"
      cidr_block = var.inspection_vpc.cidr_block
      az_count   = var.inspection_vpc.number_azs

      subnets = {
        public    = { netmask = var.inspection_vpc.public_subnet_netmask }
        endpoints = { netmask = var.inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.inspection_vpc.cnetwork_subnet_netmask

          tags = { outbound = "true" }
        }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-nvirginia"
      description = "AWS Network Firewall - us-east-1"
      policy_arn  = module.nvirginia_anfw_policy.policy_arn
    }
  }
}

# Local variable to create the subnet mapping in Outbound VPC (for multi-VPC endpoint)
locals {
  nvirginia_availability_zones = module.nvirginia_inspection_vpc.central_vpcs.outbound.azs
}

# Network Firewall VPC endpoints in Outbound VPC - resource created in Cloud WAN module
resource "awscc_networkfirewall_vpc_endpoint_association" "nvirginia_outbound_firewallendpoints" {
  count    = var.inspection_vpc.number_azs
  provider = awscc.awsccnvirginia

  description  = "Outbound VPC endpoints - N. Virginia"
  firewall_arn = module.nvirginia_inspection_vpc.aws_network_firewall["inspection"].arn
  vpc_id       = module.nvirginia_inspection_vpc.central_vpcs["outbound"].vpc_attributes.id

  subnet_mapping = {
    subnet_id = { for k, v in module.nvirginia_inspection_vpc.central_vpcs.outbound.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }[local.nvirginia_availability_zones[count.index]]
  }
}

# VPC routes pointing to the VPC endpoints created by awscc_networkfirewall_vpc_endpoint_association
# 1. From core network subnet to VPC endpoints --> 0.0.0.0/0
# 2. From public subnets to VPC endpoints --> regional supernet
resource "aws_route" "nvirginia_outboundvpc_cwan_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsnvirginia

  route_table_id         = module.nvirginia_inspection_vpc.central_vpcs["outbound"].rt_attributes_by_type_by_az.core_network[local.nvirginia_availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.nvirginia_outbound_firewallendpoints[count.index].endpoint_id
}

resource "aws_route" "nvirginia_outboundvpc_public_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsnvirginia

  route_table_id         = module.nvirginia_inspection_vpc.central_vpcs["outbound"].rt_attributes_by_type_by_az.public[local.nvirginia_availability_zones[count.index]].id
  destination_cidr_block = "10.10.0.0/16"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.nvirginia_outbound_firewallendpoints[count.index].endpoint_id
}

# AWS Network Firewall policy
module "nvirginia_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsnvirginia }

  identifier   = var.identifier
  traffic_flow = "all"
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

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
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

# Inspection VPC - definition in variables.tf
module "oregon_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.4.0"
  providers = { aws = aws.awsoregon }

  core_network_arn        = awscc_networkmanager_core_network.core_network.core_network_arn
  ipv4_network_definition = "10.20.0.0/16"

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "inspection-vpc-nvirginia"
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

    outbound = {
      type       = "egress_with_inspection"
      name       = "outbound-vpc-nvirginia"
      cidr_block = var.inspection_vpc.cidr_block
      az_count   = var.inspection_vpc.number_azs

      subnets = {
        public    = { netmask = var.inspection_vpc.public_subnet_netmask }
        endpoints = { netmask = var.inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.inspection_vpc.cnetwork_subnet_netmask

          tags = { outbound = "true" }
        }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-oregon"
      description = "AWS Network Firewall - us-west-2"
      policy_arn  = module.oregon_anfw_policy.policy_arn
    }
  }
}

# Local variable to create the subnet mapping in Outbound VPC (for multi-VPC endpoint)
locals {
  oregon_availability_zones = module.oregon_inspection_vpc.central_vpcs.outbound.azs
}

# Network Firewall VPC endpoints in Outbound VPC - resource created in Cloud WAN module
resource "awscc_networkfirewall_vpc_endpoint_association" "oregon_outbound_firewallendpoints" {
  count    = var.inspection_vpc.number_azs
  provider = awscc.awsccoregon

  description  = "Outbound VPC endpoints - Oregon"
  firewall_arn = module.oregon_inspection_vpc.aws_network_firewall["inspection"].arn
  vpc_id       = module.oregon_inspection_vpc.central_vpcs["outbound"].vpc_attributes.id

  subnet_mapping = {
    subnet_id = { for k, v in module.oregon_inspection_vpc.central_vpcs.outbound.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }[local.oregon_availability_zones[count.index]]
  }
}

# VPC routes pointing to the VPC endpoints created by awscc_networkfirewall_vpc_endpoint_association
# 1. From core network subnet to VPC endpoints --> 0.0.0.0/0
# 2. From public subnets to VPC endpoints --> regional supernet
resource "aws_route" "oregon_outboundvpc_cwan_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsoregon

  route_table_id         = module.oregon_inspection_vpc.central_vpcs["outbound"].rt_attributes_by_type_by_az.core_network[local.oregon_availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.oregon_outbound_firewallendpoints[count.index].endpoint_id
}

resource "aws_route" "oregon_outboundvpc_public_to_firewall" {
  count    = var.inspection_vpc.number_azs
  provider = aws.awsoregon

  route_table_id         = module.oregon_inspection_vpc.central_vpcs["outbound"].rt_attributes_by_type_by_az.public[local.oregon_availability_zones[count.index]].id
  destination_cidr_block = "10.20.0.0/16"
  vpc_endpoint_id        = awscc_networkfirewall_vpc_endpoint_association.oregon_outbound_firewallendpoints[count.index].endpoint_id
}

# AWS Network Firewall policy
module "oregon_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsoregon }

  identifier   = var.identifier
  traffic_flow = "all"
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
