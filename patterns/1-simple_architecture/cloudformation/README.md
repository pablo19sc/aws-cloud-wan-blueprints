# AWS Cloud WAN Simple Architecture (AWS CloudFormation)

![Simple Architecture](../../../images/patterns_simple_architecture.png)

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
cd patterns/1-simple_architecture/cloudformation

# Deploy everything (Core Network + Workloads in both regions)
make deploy

# Or deploy step-by-step:
make deploy-cloudwan    # Deploy Core Network first
make deploy-workloads   # Then deploy workloads in both regions
```

> **Note**: EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

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

1. **Explore the architecture**: Review segment associations and routing in Network Manager console
2. **Test connectivity**: Verify traffic flows match expected behavior
3. **Try modifications**: Add VPCs, change segments, update policies
4. **Advanced patterns**: Move to [Multi-Account](../../2-multi_account/), [Traffic inspection](../../3-traffic_inspection/), or [Routing policies](../../4-routing_policies/) patterns
