# AWS Cloud WAN East-West with Transit Gateway - Single-Hop (AWS CloudFormation)

![East-West TGW Single-Hop](../../../../images/east_west_tgw_spokeVpcs_singlehop.png)

## Prerequisites

- **AWS Account**: With appropriate IAM permissions
- **AWS CLI**: Installed and configured with credentials
- **Permissions required**:
  - CloudFormation
  - Network Manager
  - EC2: VPC, subnets, instances, endpoints, Network Firewall, Transit Gateway
  - IAM: Create roles and policies
- **Make**: Installed

## Deployment

```bash
# Clone the repository
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git

# Navigate to the CloudFormation directory
cd patterns/3-traffic_inspection/6-east_west_tgw_spoke_vpcs_singlehop/cloudformation

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

1. **Explore the architecture**: Review TGW route tables and Cloud WAN send-to/send-via actions
2. **Test connectivity**: Verify both intra-region and inter-region inspection via Cloud WAN
3. **Compare with dual-hop**: Deploy [Pattern 5](../../5-east_west_tgw_spoke_vpcs_dualhop/) to see the difference
4. **Advanced patterns**: Move to [Routing policies](../../../4-routing_policies/) patterns
