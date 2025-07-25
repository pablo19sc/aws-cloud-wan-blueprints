/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/3-traffic_inspection/2-east_west/terraform/cloudwan_policy.tf ---

# ---------- AWS CLOUD WAN RESOURCES ----------
# Global Network
resource "aws_networkmanager_global_network" "global_network" {
  provider = aws.awsnvirginia

  description = "Global Network - ${var.identifier}"

  tags = {
    Name = "Global Network - ${var.identifier}"
  }
}

# Core Network
resource "aws_networkmanager_core_network" "core_network" {
  provider = aws.awsnvirginia

  description       = "Core Network - ${var.identifier}"
  global_network_id = aws_networkmanager_global_network.global_network.id

  create_base_policy   = true
  base_policy_document = var.send_via_mode == "dualhop" ? data.aws_networkmanager_core_network_policy_document.policy_dualhop.json : data.aws_networkmanager_core_network_policy_document.policy_singlehop.json

  tags = {
    Name = "Core Network - ${var.identifier}"
  }
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
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
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

  core_network_arn = aws_networkmanager_core_network.core_network.arn

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

  aws_network_firewall = {
    inspection = {
      name        = "anfw-ireland"
      description = "AWS Network Firewall - eu-west-1"
      policy_arn  = module.ireland_anfw_policy.policy_arn
    }
  }
}

# AWS Network Firewall policy
module "ireland_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsireland }

  identifier   = var.identifier
  traffic_flow = "east-west"
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
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
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

  core_network_arn = aws_networkmanager_core_network.core_network.arn

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
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-nvirginia"
      description = "AWS Network Firewall - us-east-1"
      policy_arn  = module.nvirginia_anfw_policy.policy_arn
    }
  }
}

# AWS Network Firewall policy
module "nvirginia_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsnvirginia }

  identifier   = var.identifier
  traffic_flow = "east-west"
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
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
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

  core_network_arn = aws_networkmanager_core_network.core_network.arn

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

  aws_network_firewall = {
    inspection = {
      name        = "anfw-oregon"
      description = "AWS Network Firewall - us-west-2"
      policy_arn  = module.oregon_anfw_policy.policy_arn
    }
  }
}

# AWS Network Firewall policy
module "oregon_anfw_policy" {
  source    = "../../../tf_modules/firewall_policy"
  providers = { aws = aws.awsoregon }

  identifier   = var.identifier
  traffic_flow = "east-west"
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
