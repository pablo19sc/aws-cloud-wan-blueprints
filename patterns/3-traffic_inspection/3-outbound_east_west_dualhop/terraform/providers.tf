/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- patterns/3-traffic_inspection/3-outbound_east_west_dualhop/terraform/providers.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.67.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.51.0"
    }
  }
}

# Provider definition for Ireland Region
provider "aws" {
  region = var.aws_regions.ireland
  alias  = "awsireland"
}

provider "awscc" {
  region = var.aws_regions.ireland
  alias  = "awsccireland"
}

# Provider definition for N. Virginia Region
provider "aws" {
  region = var.aws_regions.nvirginia
  alias  = "awsnvirginia"
}

provider "awscc" {
  region = var.aws_regions.nvirginia
  alias  = "awsccnvirginia"
}

# Provider definition for Oregon Region
provider "aws" {
  region = var.aws_regions.oregon
  alias  = "awsoregon"
}

provider "awscc" {
  region = var.aws_regions.oregon
  alias  = "awsccoregon"
}
