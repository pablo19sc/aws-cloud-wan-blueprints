# AWS Cloud WAN Filtering Secondary CIDR Blocks (AWS CloudFormation)

![Filtering Secondary Blocks](../../../../images/patterns_filtering_secondary_cidr_blocks.png)

## Prerequisites

- **AWS Account**: With appropriate IAM permissions
- **AWS CLI**: Installed and configured with credentials
- **Permissions required**:
  - CloudFormation
  - Network Manager
  - EC2: VPC, subnets, instances, endpoints
  - IAM: Create roles and policies
- **Make**: Installed

## Deployment

```bash
# Clone the repository
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git

# Navigate to the CloudFormation directory
cd patterns/4-routing_policies/1-filtering_vpc_secondary_cidr_blocks/cloudformation

# Deploy everything
make deploy

# Or deploy step-by-step:
make deploy-cloudwan    # Deploy Core Network first
make deploy-workloads   # Then deploy workloads in both regions
```

> **Note**: This pattern demonstrates filtering secondary CIDR blocks (10.100.0.0/16) from VPC route propagation while allowing primary CIDRs to propagate normally. EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Cleanup

```bash
# Delete everything
make undeploy

# Or delete step-by-step:
make undeploy-workloads  # Delete workloads first
make undeploy-cloudwan   # Then delete Core Network
```

## Next Steps

After successfully deploying this pattern:

1. **Explore the architecture**: Review routing policies and attachment associations in Network Manager console.
2. **Test connectivity**: Verify primary CIDR connectivity works, secondary CIDR is filtered.
3. **Try modifications**: Add more VPCs with secondary CIDRs, adjust filtering rules.
4. **Advanced patterns**: Move to [IPv4/IPv6 filtering](../../2-filtering_ipv4_ipv6_only_segments/) or [BGP community filtering](../../4-filtering_by_bgp_community/) patterns.
