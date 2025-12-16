/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/4-advanced_routing/6-influencing_dxgw_hybrid_path/terraform/outputs.tf ---

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
    ireland   = module.ireland_spoke_vpc.vpc_attributes.id
    nvirginia = module.nvirginia_spoke_vpc.vpc_attributes.id
  }
}
