<!-- BEGIN_TF_DOCS -->
# East/West traffic, with Spoke VPCs attached to a peered AWS Transit Gateway (Dual-hop inspection)

![East-West-DualHop](../../../../images/east\_west\_tgw\_spokeVpcs\_dualhop.png)

## Prerequisites
- An AWS account with an IAM user with the appropriate permissions
- Terraform installed

## Code Principles:
- Writing DRY (Do No Repeat Yourself) code using a modular design pattern

## Usage
- Clone the repository
- (Optional) Edit the variables.tf file in the project root directory - if you want to test with different parameters.
- Deploy the resources using `terraform apply`.
- Remember to clean up resoures once you are done by using `terraform destroy`.

**Note** EC2 instances, VPC endpoints, and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.67.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.67.0 |
| <a name="provider_aws.awsnvirginia"></a> [aws.awsnvirginia](#provider\_aws.awsnvirginia) | >= 5.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ireland_anfw_policy"></a> [ireland\_anfw\_policy](#module\_ireland\_anfw\_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_ireland_compute"></a> [ireland\_compute](#module\_ireland\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_ireland_cwan_inspection_vpc"></a> [ireland\_cwan\_inspection\_vpc](#module\_ireland\_cwan\_inspection\_vpc) | aws-ia/cloudwan/aws | 3.2.0 |
| <a name="module_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#module\_ireland\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.4.2 |
| <a name="module_ireland_tgw_inspection_vpc"></a> [ireland\_tgw\_inspection\_vpc](#module\_ireland\_tgw\_inspection\_vpc) | aws-ia/vpc/aws | = 4.4.2 |
| <a name="module_ireland_tgw_network_firewall"></a> [ireland\_tgw\_network\_firewall](#module\_ireland\_tgw\_network\_firewall) | aws-ia/networkfirewall/aws | 1.0.0 |
| <a name="module_ireland_transit_gateway"></a> [ireland\_transit\_gateway](#module\_ireland\_transit\_gateway) | ./modules/transit_gateway | n/a |
| <a name="module_nvirginia_anfw_policy"></a> [nvirginia\_anfw\_policy](#module\_nvirginia\_anfw\_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_nvirginia_compute"></a> [nvirginia\_compute](#module\_nvirginia\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_nvirginia_cwan_inspection_vpc"></a> [nvirginia\_cwan\_inspection\_vpc](#module\_nvirginia\_cwan\_inspection\_vpc) | aws-ia/cloudwan/aws | 3.2.0 |
| <a name="module_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#module\_nvirginia\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.4.2 |
| <a name="module_nvirginia_tgw_inspection_vpc"></a> [nvirginia\_tgw\_inspection\_vpc](#module\_nvirginia\_tgw\_inspection\_vpc) | aws-ia/vpc/aws | = 4.4.2 |
| <a name="module_nvirginia_tgw_network_firewall"></a> [nvirginia\_tgw\_network\_firewall](#module\_nvirginia\_tgw\_network\_firewall) | aws-ia/networkfirewall/aws | 1.0.0 |
| <a name="module_nvirginia_transit_gateway"></a> [nvirginia\_transit\_gateway](#module\_nvirginia\_transit\_gateway) | ./modules/transit_gateway | n/a |
| <a name="module_sydney_anfw_policy"></a> [sydney\_anfw\_policy](#module\_sydney\_anfw\_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_sydney_compute"></a> [sydney\_compute](#module\_sydney\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_sydney_cwan_inspection_vpc"></a> [sydney\_cwan\_inspection\_vpc](#module\_sydney\_cwan\_inspection\_vpc) | aws-ia/cloudwan/aws | 3.2.0 |
| <a name="module_sydney_spoke_vpcs"></a> [sydney\_spoke\_vpcs](#module\_sydney\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.4.2 |
| <a name="module_sydney_tgw_inspection_vpc"></a> [sydney\_tgw\_inspection\_vpc](#module\_sydney\_tgw\_inspection\_vpc) | aws-ia/vpc/aws | = 4.4.2 |
| <a name="module_sydney_tgw_network_firewall"></a> [sydney\_tgw\_network\_firewall](#module\_sydney\_tgw\_network\_firewall) | aws-ia/networkfirewall/aws | 1.0.0 |
| <a name="module_sydney_transit_gateway"></a> [sydney\_transit\_gateway](#module\_sydney\_transit\_gateway) | ./modules/transit_gateway | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network) | resource |
| [aws_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network) | resource |
| [aws_networkmanager_core_network_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS Regions to create the environment. | `map(any)` | <pre>{<br/>  "ireland": {<br/>    "code": "eu-west-1",<br/>    "tgw_asn": 64515<br/>  },<br/>  "nvirginia": {<br/>    "code": "us-east-1",<br/>    "tgw_asn": 64516<br/>  },<br/>  "sydney": {<br/>    "code": "ap-southeast-2",<br/>    "tgw_asn": 64517<br/>  }<br/>}</pre> | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project Identifier, used as identifer when creating resources. | `string` | `"ew-tgw-spoke-vpcs"` | no |
| <a name="input_ireland_inspection_vpc"></a> [ireland\_inspection\_vpc](#input\_ireland\_inspection\_vpc) | Information about the Inspection VPC to create in eu-west-1. | `any` | <pre>{<br/>  "cidr_block": "10.100.0.0/16",<br/>  "connectivity_subnet_netmask": 28,<br/>  "inspection_subnet_netmask": 28,<br/>  "name": "inspection-eu-west-1",<br/>  "number_azs": 2<br/>}</pre> | no |
| <a name="input_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#input\_ireland\_spoke\_vpcs) | Information about the VPCs to create in eu-west-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.0.1.0/24",<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "tgw_subnet_netmask": 28,<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.0.0.0/24",<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "tgw_subnet_netmask": 28,<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_nvirginia_inspection_vpc"></a> [nvirginia\_inspection\_vpc](#input\_nvirginia\_inspection\_vpc) | Information about the Inspection VPC to create in us-east-1. | `any` | <pre>{<br/>  "cidr_block": "10.100.0.0/16",<br/>  "connectivity_subnet_netmask": 28,<br/>  "inspection_subnet_netmask": 28,<br/>  "name": "inspection-us-east-1",<br/>  "number_azs": 2<br/>}</pre> | no |
| <a name="input_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#input\_nvirginia\_spoke\_vpcs) | Information about the VPCs to create in us-east-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.10.1.0/24",<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "tgw_subnet_netmask": 28,<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.10.0.0/24",<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "tgw_subnet_netmask": 28,<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_sydney_inspection_vpc"></a> [sydney\_inspection\_vpc](#input\_sydney\_inspection\_vpc) | Information about the Inspection VPC to create in ap-southeast-2. | `any` | <pre>{<br/>  "cidr_block": "10.100.0.0/16",<br/>  "connectivity_subnet_netmask": 28,<br/>  "inspection_subnet_netmask": 28,<br/>  "name": "insp-ap-southeast-2",<br/>  "number_azs": 2<br/>}</pre> | no |
| <a name="input_sydney_spoke_vpcs"></a> [sydney\_spoke\_vpcs](#input\_sydney\_spoke\_vpcs) | Information about the VPCs to create in ap-southeast-2. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.20.1.0/24",<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-ap-southeast-2",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "tgw_subnet_netmask": 28,<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.20.0.0/24",<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-ap-southeast-2",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "tgw_subnet_netmask": 28,<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
