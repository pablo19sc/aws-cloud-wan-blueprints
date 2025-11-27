/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/4-advanced_routing/5-influencing_hybrid_path_between_cnes/terraform/variables.tf ---

# Project Identifier
variable "identifier" {
  type        = string
  description = "Project Identifier, used as identifer when creating resources."
  default     = "influencing-hybrid-between-cnes"
}

# AWS Regions
variable "aws_regions" {
  type        = map(string)
  description = "AWS Regions to create the environment."
  default = {
    ireland   = "eu-west-1"
    nvirginia = "us-east-1"
    london    = "eu-west-2"
  }
}

# Definition of the VPC to create in Ireland Region
variable "ireland_spoke_vpc" {
  type        = map(any)
  description = "Information about the VPC to create in eu-west-1."

  default = {
    name                    = "vpc-eu-west-1"
    number_azs              = 2
    cidr_block              = "10.0.0.0/24"
    workload_subnet_netmask = 28
    endpoint_subnet_netmask = 28
    cnetwork_subnet_netmask = 28
    instance_type           = "t2.micro"
  }
}

# Definition of the VPC to create in N. Virginia Region
variable "nvirginia_spoke_vpc" {
  type        = map(any)
  description = "Information about the VPC to create in us-east-1."

  default = {
    name                    = "vpc-us-east-1"
    number_azs              = 2
    cidr_block              = "10.10.0.0/24"
    workload_subnet_netmask = 28
    endpoint_subnet_netmask = 28
    cnetwork_subnet_netmask = 28
    instance_type           = "t2.micro"
  }
}

# Definition of the VPC to create in London Region
variable "london_spoke_vpc" {
  type        = map(any)
  description = "Information about the VPC to create in eu-west-2."

  default = {
    name                    = "vpc-eu-west-2"
    number_azs              = 2
    cidr_block              = "10.20.0.0/24"
    workload_subnet_netmask = 28
    endpoint_subnet_netmask = 28
    cnetwork_subnet_netmask = 28
    instance_type           = "t2.micro"
  }
}


