/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/2-multi_account/terraform/spoke/outputs.tf ---

output "vpcs" {
  description = "VPCs created."
  value = {
    ireland   = { for k, v in module.ireland_spoke_vpcs : k => v.vpc_attributes.id }
    nvirginia = { for k, v in module.nvirginia_spoke_vpcs : k => v.vpc_attributes.id }
  }
}
