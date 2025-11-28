# AWS Cloud WAN Centralized Outbound - Region Without Inspection (AWS CloudFormation)

![Centralized Outbound - Region Without Inspection](../../../../images/centralizedOutbound_regionWithoutInspection.png)

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
cd patterns/3-traffic_inspection/2-centralized_outbound_region_without_inspection/cloudformation

# Deploy everything (Core Network + Workloads in all regions)
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

1. **Explore the architecture**: Review edge overrides in Network Manager console
2. **Test connectivity**: Verify eu-west-2 traffic is inspected in eu-west-1
3. **Try modifications**: Add more regions without inspection, adjust edge overrides
4. **Advanced patterns**: Move to [East-West patterns](../../3-east_west_dualhop/) or [Routing policies](../../../4-routing_policies/) patterns
