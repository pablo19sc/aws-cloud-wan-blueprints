# AWS Cloud WAN IPv4/IPv6 Segment Filtering (AWS CloudFormation)

![IPv4-IPv6 Segments](../../../../images/patterns_filtering_ipv4_ipv6_segments.png)

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
cd patterns/4-routing_policies/2-filtering_ipv4_ipv6_only_segments/cloudformation

# Deploy everything
make deploy

# Or deploy step-by-step:
make deploy-cloudwan    # Deploy Core Network first
make deploy-workloads   # Then deploy workloads in both regions
```

> **Note**: This pattern creates protocol-specific segments by filtering IPv4 or IPv6 routes when sharing between dual-stack and single-stack segments. EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

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

1. **Explore the architecture**: Review segment sharing with routing policies in Network Manager console
2. **Test connectivity**: Verify IPv4-only and IPv6-only segments receive appropriate routes
3. **Try modifications**: Add more protocol-specific segments, test dual-stack connectivity
4. **Advanced patterns**: Move to [BGP community filtering](../../4-filtering_by_bgp_community/) or [Path influence](../../5-influencing_hybrid_path_between_cnes/) patterns
