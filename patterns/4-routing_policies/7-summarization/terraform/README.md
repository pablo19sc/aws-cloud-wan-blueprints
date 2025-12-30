<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN Route Summarization (Terraform)

![Summarization](../../../../images/patterns\_summarization.png)

> **⚠️ Hybrid Environment Required**: This pattern requires you to establish hybrid connectivity (Site-to-Site VPN, Connect attachment, or Direct Connect Gateway) with BGP configuration to test end-to-end. The IaC code creates the Cloud WAN infrastructure, but you must configure your on-premises router to establish BGP sessions.

## Prerequisites

- **AWS Account**: With appropriate IAM permissions
- **Terraform**: >= 1.3.0 installed
- **AWS CLI**: Configured with credentials (required for prefix list association)
- **Permissions required**:
  - Network Manager
  - EC2: VPC, subnets, instances, endpoints, prefix lists
  - IAM: Create roles and policies
- **Hybrid Connectivity**: Site-to-Site VPN, Connect attachment, or Direct Connect Gateway for full testing

## Deployment

```bash
# Clone the repository
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git

# Navigate to the Terraform directory
cd patterns/4-routing_policies/7-summarization/terraform

# Initialize Terraform
terraform init

# Deploy the resources
terraform apply
```

> **Important Notes**:
> 1. **Prefix List Association Region**: The prefix list association MUST be created in `us-west-2` as it is Cloud WAN's home region, regardless of where your Core Network edge locations are deployed.
> 2. **Routing Policy Label**: After deployment, when you create your hybrid connections (Site-to-Site VPN, Connect, or Direct Connect Gateway), you MUST add the routing policy label `hybridAttachment` to the attachment for the summarization policy to be applied.
> 3. **Dual-Stack VPCs**: VPCs are deployed as dual-stack (IPv4 and IPv6), but the summarization policy only applies to IPv4 CIDR blocks. IPv6 routes will be advertised without summarization.

## Cleanup

We need first to restore the Core Network policy version to the one with the `base_policy` configuration to remove the prefix list reference. Once this update, we can proceed and remove all the resources at once.

```bash
# Get core network ID
CORE_NETWORK_ID=$(terraform output -json cloud_wan | jq -r '.core_network')

# Restore
aws networkmanager restore-core-network-policy-version \
  --core-network-id $CORE_NETWORK_ID \
  --policy-version-id 1 \
  --region us-west-2

# Check status. Do not proceed to the next command until READY_TO_EXECUTE
aws networkmanager get-core-network-policy \
  --core-network-id $CORE_NETWORK_ID \
  --region us-west-2 \
  --query 'CoreNetworkPolicy.ChangeSetState'

# Execute
aws networkmanager execute-core-network-change-set \
  --core-network-id $CORE_NETWORK_ID \
  --policy-version-id <new-version-from-restore> \
  --region us-west-2

# Check status. Do not proceed to the next command until EXECUTED
aws networkmanager get-core-network-policy \
  --core-network-id $CORE_NETWORK_ID \
  --region us-west-2 \
  --query 'CoreNetworkPolicy.ChangeSetState'

# Destroy all resources
terraform destroy
```

## Next Steps

After successfully deploying this pattern:

1. **Explore the architecture**: Review routing policies and prefix list associations in Network Manager console
2. **Test connectivity**: Establish hybrid connectivity with the `hybridAttachment` routing policy label
3. **Verify summarization**: Check BGP routes advertised to on-premises to confirm summarization is working
4. **Try modifications**: Adjust summary routes, add more prefix lists, test different summarization scenarios

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.67.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.awsnvirginia"></a> [aws.awsnvirginia](#provider\_aws.awsnvirginia) | 6.27.0 |
| <a name="provider_aws.awsoregon"></a> [aws.awsoregon](#provider\_aws.awsoregon) | 6.27.0 |
| <a name="provider_awscc.awsccoregon"></a> [awscc.awsccoregon](#provider\_awscc.awsccoregon) | 1.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ireland_compute"></a> [ireland\_compute](#module\_ireland\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#module\_ireland\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.7.3 |
| <a name="module_nvirginia_compute"></a> [nvirginia\_compute](#module\_nvirginia\_compute) | ../../../tf_modules/compute | n/a |
| <a name="module_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#module\_nvirginia\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.7.3 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_managed_prefix_list.ipv4_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list) | resource |
| [aws_ec2_managed_prefix_list_entry.ireland_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list_entry) | resource |
| [aws_ec2_managed_prefix_list_entry.nvirginia_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list_entry) | resource |
| [aws_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network) | resource |
| [aws_networkmanager_core_network_policy_attachment.core_network_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network_policy_attachment) | resource |
| [aws_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network) | resource |
| [awscc_networkmanager_core_network_prefix_list_association.prefix_list_association](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_core_network_prefix_list_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS Regions to create the environment. | `map(string)` | <pre>{<br/>  "ireland": "eu-west-1",<br/>  "nvirginia": "us-east-1"<br/>}</pre> | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project Identifier, used as identifer when creating resources. | `string` | `"summarization-outbound"` | no |
| <a name="input_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#input\_ireland\_spoke\_vpcs) | Information about the VPCs to create in eu-west-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.0.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.0.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-eu-west-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |
| <a name="input_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#input\_nvirginia\_spoke\_vpcs) | Information about the VPCs to create in us-east-1. | `any` | <pre>{<br/>  "dev": {<br/>    "cidr_block": "10.10.1.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "dev-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "development",<br/>    "workload_subnet_netmask": 28<br/>  },<br/>  "prod": {<br/>    "cidr_block": "10.10.0.0/24",<br/>    "cnetwork_subnet_netmask": 28,<br/>    "endpoint_subnet_netmask": 28,<br/>    "instance_type": "t2.micro",<br/>    "name": "prod-us-east-1",<br/>    "number_azs": 2,<br/>    "segment": "production",<br/>    "workload_subnet_netmask": 28<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_wan"></a> [cloud\_wan](#output\_cloud\_wan) | AWS Cloud WAN resources. |
| <a name="output_prefix_list"></a> [prefix\_list](#output\_prefix\_list) | Prefix List (IPv4). |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->