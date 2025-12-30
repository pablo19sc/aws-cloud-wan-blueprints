/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/4-advanced_routing/8-filtering_peered_tgw/terraform/variables.tf ---

# Project Identifier
variable "identifier" {
  type        = string
  description = "Project Identifier, used as identifer when creating resources."
  default     = "filtering-peered-tgw"
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

# Transit Gateway ASN
variable "tgw_asn" {
  type        = map(number)
  description = "AWS Transit Gateway ASN number."
  default = {
    ireland   = 65500
    nvirginia = 65501
  }
}

# Definition of the VPCs to create in Ireland Region
variable "ireland_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in eu-west-1."

  default = {
    "vpc1" = {
      name                    = "vpc1-eu-west-1"
      number_azs              = 2
      cidr_block              = "10.0.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"
    }
    "vpc2" = {
      name                    = "vpc2-eu-west-1"
      number_azs              = 2
      cidr_block              = "10.0.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"
    }
  }
}

# Definition of the VPCs to create in N. Virginia Region
variable "nvirginia_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in us-east-1."

  default = {
    "vpc1" = {
      name                    = "vpc1-us-east-1"
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.10.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"
    }
    "vpc2" = {
      name                    = "vpc2-us-east-1"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.10.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"
    }
  }
}