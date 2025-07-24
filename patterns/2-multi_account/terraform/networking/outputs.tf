/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/2-multi_account/terraform/networking/outputs.tf ---

output "cloud_wan" {
  description = "AWS Cloud WAN resources."
  value = {
    global_network = aws_networkmanager_global_network.global_network.id
    core_network   = aws_networkmanager_core_network.core_network.id
  }
}

output "resource_share_arn" {
  description = "AWS RAM resource share ARN."
  value       = aws_ram_resource_share.resource_share.arn
}
