# AWS Cloud WAN Traffic Inspection After Filtering (AWS CloudFormation)

![Inspection after Filtering](../../../../images/patterns_inspection_after_filtering.png)

## Prerequisites

- **AWS Account**: With appropriate IAM permissions
- **AWS CLI**: Installed and configured with credentials
- **Permissions required**:
  - CloudFormation
  - Network Manager
  - EC2: VPC, subnets, instances, endpoints, Network Firewall
  - IAM: Create roles and policies
- **Make**: Installed

## Deployment

```bash
# Clone the repository
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git

# Navigate to the CloudFormation directory
cd patterns/4-routing_policies/3-inspection_after_filtering/cloudformation

# Deploy everything
make deploy

# Or deploy step-by-step:
make deploy-cloudwan    # Deploy Core Network first
make deploy-inspection  # Deploy inspection VPCs with AWS Network Firewall
make deploy-workloads   # Then deploy workloads in both regions
```

> **Note**: EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Cleanup

```bash
# Delete everything
make undeploy

# Or delete step-by-step:
make undeploy-resources  # Delete workloads and inspection first
make undeploy-cloudwan   # Then delete Core Network
```

## Next Steps

After successfully deploying this pattern:

1. **Explore the architecture**: Review routing policies, Network Function Groups, and service insertion in Network Manager console
2. **Test connectivity**: Verify traffic between production and development segments flows through inspection VPCs
3. **Verify filtering**: Confirm secondary CIDR blocks (100.64.0.0/16) are filtered and not propagated
4. **Check firewall logs**: Review AWS Network Firewall logs to see inspected traffic
5. **Try modifications**: Adjust routing policies to filter different CIDR ranges or add more segments
