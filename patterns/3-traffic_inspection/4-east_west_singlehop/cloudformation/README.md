# AWS Cloud WAN East-West Inspection - Single-Hop (AWS CloudFormation)

![East-West Single-Hop](../../../../images/east_west_singlehop.png)

In the example in this repository, the following matrix is used to determine which inspection VPC is used for traffic inspection:

| *AWS Region*       | us-east-1 | eu-west-1 | eu-west-2      | ap-south-east-2 |
| --------------     |:---------:| ---------:| --------------:| ---------------:|
| **us-east-1**      | us-east-1 | us-east-1 | us-east-1      | us-east-1       |
| **eu-west-1**      | us-east-1 | eu-west-1 | eu-west-1      | eu-west-1       |
| **eu-west-2**      | us-east-1 | eu-west-1 | eu-west-1      | ap-southeast-2  |
| **ap-southeast-2** | us-east-1 | eu-west-1 | ap-southeast-2 | ap-southeast-2  |

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
cd patterns/3-traffic_inspection/4-east_west_singlehop/cloudformation

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

1. **Explore the architecture**: Review send-via with edge overrides in Network Manager console
2. **Test connectivity**: Verify cross-region traffic is inspected once
3. **Compare with dual-hop**: Deploy [Pattern 3](../../3-east_west_dualhop/) to see the difference
4. **Advanced patterns**: Move to [Routing policies](../../../4-routing_policies/) patterns
