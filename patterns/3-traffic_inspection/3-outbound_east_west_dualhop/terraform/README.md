<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN Blueprints - Traffic Inspection architectures (Centralized Outbound & East-West dual-hop)

![Centralized Outbound & East-West dual-hop](../../../../images/patterns\_outbound\_eastwest\_dualhop.png)

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
cd patterns/3-traffic_inspection/3-outbound_east_west_dualhop/terraform
```

- (Optional) Edit the variables.tf file in the project root directory - if you want to test with different parameters.
- Deploy the resources using `terraform apply`.
- Remember to clean up resoures once you are done by using `terraform destroy`.

**Note** EC2 instances and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.67.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.7.0 |
| <a name="provider_aws.awsireland"></a> [aws.awsireland](#provider\_aws.awsireland) | 6.7.0 |
| <a name="provider_aws.awsnvirginia"></a> [aws.awsnvirginia](#provider\_aws.awsnvirginia) | 6.7.0 |
| <a name="provider_aws.awsoregon"></a> [aws.awsoregon](#provider\_aws.awsoregon) | 6.7.0 |
| <a name="provider_awscc.awsccireland"></a> [awscc.awsccireland](#provider\_awscc.awsccireland) | 1.51.0 |
| <a name="provider_awscc.awsccnvirginia"></a> [awscc.awsccnvirginia](#provider\_awscc.awsccnvirginia) | 1.51.0 |
| <a name="provider_awscc.awsccoregon"></a> [awscc.awsccoregon](#provider\_awscc.awsccoregon) | 1.51.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ireland_anfw_policy"></a> [ireland\_anfw\_policy](#module\_ireland\_anfw\_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_ireland_compute"></a> [ireland\_compute](#module\_ireland\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_ireland_inspection_vpc"></a> [ireland\_inspection\_vpc](#module\_ireland\_inspection\_vpc) | aws-ia/cloudwan/aws | 3.4.0 |
| <a name="module_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#module\_ireland\_spoke\_vpcs) | aws-ia/vpc/aws | 4.5.0 |
| <a name="module_nvirginia_anfw_policy"></a> [nvirginia\_anfw\_policy](#module\_nvirginia\_anfw\_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_nvirginia_compute"></a> [nvirginia\_compute](#module\_nvirginia\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_nvirginia_inspection_vpc"></a> [nvirginia\_inspection\_vpc](#module\_nvirginia\_inspection\_vpc) | aws-ia/cloudwan/aws | 3.4.0 |
| <a name="module_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#module\_nvirginia\_spoke\_vpcs) | aws-ia/vpc/aws | 4.5.0 |
| <a name="module_oregon_anfw_policy"></a> [oregon\_anfw\_policy](#module\_oregon\_anfw\_policy) | ../../../tf_modules/firewall_policy | n/a |
| <a name="module_oregon_compute"></a> [oregon\_compute](#module\_oregon\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_oregon_inspection_vpc"></a> [oregon\_inspection\_vpc](#module\_oregon\_inspection\_vpc) | aws-ia/cloudwan/aws | 3.4.0 |
| <a name="module_oregon_spoke_vpcs"></a> [oregon\_spoke\_vpcs](#module\_oregon\_spoke\_vpcs) | aws-ia/vpc/aws | 4.5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route.ireland_outboundvpc_cwan_to_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.ireland_outboundvpc_public_to_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nvirginia_outboundvpc_cwan_to_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nvirginia_outboundvpc_public_to_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.oregon_outboundvpc_cwan_to_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.oregon_outboundvpc_public_to_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [awscc_networkfirewall_vpc_endpoint_association.ireland_outbound_firewallendpoints](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkfirewall_vpc_endpoint_association) | resource |
| [awscc_networkfirewall_vpc_endpoint_association.nvirginia_outbound_firewallendpoints](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkfirewall_vpc_endpoint_association) | resource |
| [awscc_networkfirewall_vpc_endpoint_association.oregon_outbound_firewallendpoints](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkfirewall_vpc_endpoint_association) | resource |
| [awscc_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_core_network) | resource |
| [awscc_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_global_network) | resource |
| [aws_networkmanager_core_network_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS Regions to create the environment. | `map(string)` | <pre>{<br/>  "ireland": "eu-west-1",<br/>  "nvirginia": "us-east-1",<br/>  "oregon": "us-west-2"<br/>}</pre> | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project Identifier, used as identifer when creating resources. | `string` | `"outbound-eastwest-dualhop"` | no |
| <a name="input_inspection_vpc"></a> [inspection\_vpc](#input\_inspection\_vpc) | Information about the Inspection VPC. | `any` | <pre>{<br/>  "cidr_block": "10.100.0.0/16",<br/>  "cnetwork_subnet_netmask": 28,<br/>  "inspection_subnet_netmask": 28,<br/>  "number_azs": 2,<br/>  "public_subnet_netmask": 28<br/>}</pre> | no |
| <a name="input_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#input\_ireland\_spoke\_vpcs) | Information about the VPCs to create in eu-west-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.0.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.0.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#input\_nvirginia\_spoke\_vpcs) | Information about the VPCs to create in us-east-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.10.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.10.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_oregon_spoke_vpcs"></a> [oregon\_spoke\_vpcs](#input\_oregon\_spoke\_vpcs) | Information about the VPCs to create in us-west-2. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.20.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-us-west-2",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.20.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-us-west-2",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->