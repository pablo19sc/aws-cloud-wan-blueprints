<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN advanced routing - Influencing hybrid path between AWS Regions (Terraform)

![Filtering-BGP-Community](../../../../images/patterns\_filtering\_bgp\_community.png)

## Prerequisites
- An AWS account with an IAM user with the appropriate permissions.
- Terraform installed.

## Code Principles:
- Writing DRY (Do No Repeat Yourself) code using a modular design pattern

## Usage
- Clone the repository

```bash
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git
```

- Move to the corresponding folder

```bash
cd patterns/4-routing_policies/5-influencing_hybrid_path_between_cnes/terraform
```

- (Optional) Edit the variables.tf file in the project root directory - if you want to test with different parameters.
- Deploy the resources using `terraform apply`.
- Remember to clean up resoures once you are done by using `terraform destroy`.

**Note** EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ireland_compute"></a> [ireland\_compute](#module\_ireland\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_ireland_spoke_vpc"></a> [ireland\_spoke\_vpc](#module\_ireland\_spoke\_vpc) | aws-ia/vpc/aws | = 4.7.3 |
| <a name="module_london_compute"></a> [london\_compute](#module\_london\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_london_spoke_vpc"></a> [london\_spoke\_vpc](#module\_london\_spoke\_vpc) | aws-ia/vpc/aws | = 4.7.3 |
| <a name="module_nvirginia_compute"></a> [nvirginia\_compute](#module\_nvirginia\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_nvirginia_spoke_vpc"></a> [nvirginia\_spoke\_vpc](#module\_nvirginia\_spoke\_vpc) | aws-ia/vpc/aws | = 4.7.3 |

## Resources

| Name | Type |
|------|------|
| [awscc_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_core_network) | resource |
| [awscc_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_global_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS Regions to create the environment. | `map(string)` | <pre>{<br/>  "ireland": "eu-west-1",<br/>  "london": "eu-west-2",<br/>  "nvirginia": "us-east-1"<br/>}</pre> | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project Identifier, used as identifer when creating resources. | `string` | `"influencing-hybrid-between-cnes"` | no |
| <a name="input_ireland_spoke_vpc"></a> [ireland\_spoke\_vpc](#input\_ireland\_spoke\_vpc) | Information about the VPC to create in eu-west-1. | `map(any)` | <pre>{<br/>  "cidr_block": "10.0.0.0/24",<br/>  "cnetwork_subnet_netmask": 28,<br/>  "endpoint_subnet_netmask": 28,<br/>  "instance_type": "t2.micro",<br/>  "name": "vpc-eu-west-1",<br/>  "number_azs": 2,<br/>  "workload_subnet_netmask": 28<br/>}</pre> | no |
| <a name="input_london_spoke_vpc"></a> [london\_spoke\_vpc](#input\_london\_spoke\_vpc) | Information about the VPC to create in eu-west-2. | `map(any)` | <pre>{<br/>  "cidr_block": "10.20.0.0/24",<br/>  "cnetwork_subnet_netmask": 28,<br/>  "endpoint_subnet_netmask": 28,<br/>  "instance_type": "t2.micro",<br/>  "name": "vpc-eu-west-2",<br/>  "number_azs": 2,<br/>  "workload_subnet_netmask": 28<br/>}</pre> | no |
| <a name="input_nvirginia_spoke_vpc"></a> [nvirginia\_spoke\_vpc](#input\_nvirginia\_spoke\_vpc) | Information about the VPC to create in us-east-1. | `map(any)` | <pre>{<br/>  "cidr_block": "10.10.0.0/24",<br/>  "cnetwork_subnet_netmask": 28,<br/>  "endpoint_subnet_netmask": 28,<br/>  "instance_type": "t2.micro",<br/>  "name": "vpc-us-east-1",<br/>  "number_azs": 2,<br/>  "workload_subnet_netmask": 28<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_wan"></a> [cloud\_wan](#output\_cloud\_wan) | AWS Cloud WAN resources. |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->