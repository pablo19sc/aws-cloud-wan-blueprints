# AWS Cloud WAN BGP Community Filtering (AWS CloudFormation)

![Filtering BGP Community](../../../../images/patterns_filtering_bgp_community.png)

> **⚠️ Hybrid Environment Required**: This pattern requires you to establish hybrid connectivity (Site-to-Site VPN or Connect attachment) with BGP configuration to test end-to-end. The IaC code creates the Cloud WAN infrastructure, but you must configure your on-premises router to advertise routes with BGP communities.

## Prerequisites

- **AWS Account**: With appropriate IAM permissions
- **AWS CLI**: Installed and configured with credentials
- **Permissions required**:
  - CloudFormation
  - Network Manager
  - EC2: VPC, subnets, instances, endpoints
  - IAM: Create roles and policies
- **Make**: Installed
- **Hybrid Connectivity**: Site-to-Site VPN or Connect attachment for full testing

## Deployment

```bash
# Clone the repository
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git

# Navigate to the CloudFormation directory
cd patterns/4-routing_policies/4-filtering_by_bgp_community/cloudformation

# Deploy everything
make deploy

# Or deploy step-by-step:
make deploy-cloudwan    # Deploy Core Network first
make deploy-workloads   # Then deploy workloads in both regions
```

> **Note**: This pattern segments hybrid traffic by BGP community. For end-to-end testing, establish Site-to-Site VPN or Connect attachment with BGP communities (65052:100 for development, 65051:100 for test). EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

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

1. **Explore the architecture**: Review routing policies and segment sharing in Network Manager console
2. **Test connectivity**: Establish hybrid connectivity and verify BGP community filtering
3. **Try modifications**: Add more BGP communities, create additional segments
4. **Advanced patterns**: Move to [Path influence](../../5-influencing_hybrid_path_between_cnes/) patterns
