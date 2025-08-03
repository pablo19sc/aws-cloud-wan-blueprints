/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/3-traffic_inspection/2-east_west/terraform/outputs.tf ---

output "cloud_wan" {
  description = "AWS Cloud WAN resources."
  value = {
    global_network = awscc_networkmanager_global_network.global_network.id
    core_network   = awscc_networkmanager_core_network.core_network.core_network_id
  }
}

output "vpcs" {
  description = "VPCs created."
  value = {
    ireland = {
      spokes     = { for k, v in module.ireland_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.ireland_inspection_vpc.central_vpcs.inspection.vpc_attributes.id
    }
    nvirginia = {
      spokes     = { for k, v in module.nvirginia_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.nvirginia_inspection_vpc.central_vpcs.inspection.vpc_attributes.id
    }
    oregon = {
      spokes     = { for k, v in module.oregon_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.oregon_inspection_vpc.central_vpcs.inspection.vpc_attributes.id
    }
  }
}
