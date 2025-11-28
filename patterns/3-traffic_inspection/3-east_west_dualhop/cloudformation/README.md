# AWS Cloud WAN East-West Inspection - Dual-Hop (AWS CloudFormation)

![East-West Dual-Hop](../../../../images/east_west_dualhop.png)

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
cd patterns/3-traffic_inspection/3-east_west_dualhop/cloudformation

# Deploy everything
make deploy
```

> **Note**: EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Cleanup

```bash
# Delete everything
make undeploy
```

## Next Steps

After successfully deploying this pattern:

1. **Explore the architecture**: Review send-via actions in Network Manager console
2. **Test connectivity**: Verify cross-region traffic is inspected twice
3. **Compare with single-hop**: Deploy [Pattern 4](../../4-east_west_singlehop/) to see the difference
4. **Advanced patterns**: Move to [Routing policies](../../../4-routing_policies/) patterns
