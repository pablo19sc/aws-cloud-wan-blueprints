/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/2-multi_account/terraform/spoke/providers.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.67.0"
    }
  }
}

# Provider definitios for Ireland Region
provider "aws" {
  region = var.aws_regions.ireland
  alias  = "awsireland"
}

# Provider definitios for N. Virginia Region
provider "aws" {
  region = var.aws_regions.nvirginia
  alias  = "awsnvirginia"
}
