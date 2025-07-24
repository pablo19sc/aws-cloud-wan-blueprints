/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/2-multi_account/terraform/networking/variables.tf ---

# Project Identifier
variable "identifier" {
  type        = string
  description = "Project Identifier, used as identifer when creating resources."
  default     = "multi-account"
}

# AWS Regions
variable "aws_regions" {
  type        = map(string)
  description = "AWS Regions to create the environment."
  default = {
    ireland   = "eu-west-1"
    nvirginia = "us-east-1"
  }
}

# Spoke AWS Account (default not provided)
variable "spoke_account" {
  type        = string
  description = "Spoke AWS Account."
}
