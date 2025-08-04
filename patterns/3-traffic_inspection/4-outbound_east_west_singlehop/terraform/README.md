<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN Blueprints - Traffic Inspection architectures (Centralized Outbound & East-West single-hop)

![Centralized Outbound & East-West single-hop](../../../../images/patterns_outbound_eastwest_singlehop.png)

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
cd patterns/3-traffic_inspection/4-outbound_east_west_singlehop/terraform
```

- (Optional) Edit the variables.tf file in the project root directory - if you want to test with different parameters.
- Deploy the resources using `terraform apply`.
- Remember to clean up resoures once you are done by using `terraform destroy`.

**Note** EC2 instances and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | >= 5.67.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement_awscc) | >= 1.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.7.0 |
| <a name="provider_awscc"></a> [awscc](#provider_awscc) | 1.51.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ireland_anfw_policy"></a> [ireland_anfw_policy](#module_ireland_anfw_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_ireland_compute"></a> [ireland_compute](#module_ireland_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_ireland_inspection_vpc"></a> [ireland_inspection_vpc](#module_ireland_inspection_vpc) | aws-ia/cloudwan/aws | 3.4.0 |
| <a name="module_ireland_spoke_vpcs"></a> [ireland_spoke_vpcs](#module_ireland_spoke_vpcs) | aws-ia/vpc/aws | 4.5.0 |
| <a name="module_nvirginia_anfw_policy"></a> [nvirginia_anfw_policy](#module_nvirginia_anfw_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_nvirginia_compute"></a> [nvirginia_compute](#module_nvirginia_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_nvirginia_inspection_vpc"></a> [nvirginia_inspection_vpc](#module_nvirginia_inspection_vpc) | aws-ia/cloudwan/aws | 3.4.0 |
| <a name="module_nvirginia_spoke_vpcs"></a> [nvirginia_spoke_vpcs](#module_nvirginia_spoke_vpcs) | aws-ia/vpc/aws | 4.5.0 |
| <a name="module_oregon_anfw_policy"></a> [oregon_anfw_policy](#module_oregon_anfw_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_oregon_compute"></a> [oregon_compute](#module_oregon_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_oregon_inspection_vpc"></a> [oregon_inspection_vpc](#module_oregon_inspection_vpc) | aws-ia/cloudwan/aws | 3.4.0 |
| <a name="module_oregon_spoke_vpcs"></a> [oregon_spoke_vpcs](#module_oregon_spoke_vpcs) | aws-ia/vpc/aws | 4.5.0 |

## Resources

| Name | Type |
|------|------|
| [awscc_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_core_network) | resource |
| [awscc_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_global_network) | resource |
| [aws_networkmanager_core_network_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws_regions](#input_aws_regions) | AWS Regions to create the environment. | `map(string)` | <pre>{<br/>  "ireland": "eu-west-1",<br/>  "nvirginia": "us-east-1",<br/>  "oregon": "us-west-2"<br/>}</pre> | no |
| <a name="input_identifier"></a> [identifier](#input_identifier) | Project Identifier, used as identifer when creating resources. | `string` | `"outbound-eastwest-singlehop"` | no |
| <a name="input_inspection_vpc"></a> [inspection_vpc](#input_inspection_vpc) | Information about the Inspection VPC. | `any` | <pre>{<br/>  "cidr_block": "10.100.0.0/16",<br/>  "cnetwork_subnet_netmask": 28,<br/>  "inspection_subnet_netmask": 28,<br/>  "number_azs": 2,<br/>  "public_subnet_netmask": 28<br/>}</pre> | no |
| <a name="input_ireland_spoke_vpcs"></a> [ireland_spoke_vpcs](#input_ireland_spoke_vpcs) | Information about the VPCs to create in eu-west-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.0.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.0.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_nvirginia_spoke_vpcs"></a> [nvirginia_spoke_vpcs](#input_nvirginia_spoke_vpcs) | Information about the VPCs to create in us-east-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.10.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.10.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_oregon_spoke_vpcs"></a> [oregon_spoke_vpcs](#input_oregon_spoke_vpcs) | Information about the VPCs to create in us-west-2. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.20.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-us-west-2",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.20.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-us-west-2",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
