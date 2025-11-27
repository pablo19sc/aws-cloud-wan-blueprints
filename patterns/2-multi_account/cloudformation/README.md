# AWS Cloud WAN Multi-Account architecture (AWS CloudFormation)

![Multi-Account Architecture](../../../images/patterns_multi_account.png)

## Prerequisites

- **Two AWS Accounts**: Networking Account and Spoke Account
- **AWS CLI**: Installed and configured with credentials for both accounts
- **Permissions required**:
  - **Networking Account**: CloudFormation, Network Manager, RAM
  - **Spoke Account**: CloudFormation, EC2 (VPC, subnets, instances, endpoints), IAM, RAM
- **Spoke Account ID**: Required for deployment

## Deployment

### Step 1: Deploy Core Network (Networking Account)

```bash
# Clone the repository
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git
cd patterns/2-multi_account/cloudformation

# Set the Spoke Account ID
export SPOKE_ACCOUNT="<your-spoke-account-id>"

# Assume credentials for Networking Account
# Deploy Core Network and RAM share
aws cloudformation deploy \
  --stack-name core-network-multi-account \
  --template-file core_network.yaml \
  --parameter-overrides SpokeAccount="${SPOKE_ACCOUNT}" \
  --region us-east-1
```

### Step 2: Get Core Network outputs (Networking Account)

```bash
# Get Core Network ID
export CORENETWORK_ID=$(aws cloudformation describe-stacks \
  --stack-name core-network-multi-account \
  --query 'Stacks[0].Outputs[?OutputKey==`CoreNetworkId`].OutputValue' \
  --output text \
  --region us-east-1)

# Get Core Network ARN
export CORENETWORK_ARN=$(aws cloudformation describe-stacks \
  --stack-name core-network-multi-account \
  --query 'Stacks[0].Outputs[?OutputKey==`CoreNetworkArn`].OutputValue' \
  --output text \
  --region us-east-1)

# Get RAM Resource Share ARN
export RESOURCE_SHARE_ARN=$(aws cloudformation describe-stacks \
  --stack-name core-network-multi-account \
  --query 'Stacks[0].Outputs[?OutputKey==`ResourceShareArn`].OutputValue' \
  --output text \
  --region us-east-1)
```

### Step 3: Accept RAM Share (Spoke Account)

> **Note**: If accounts are in the same AWS Organization with RAM sharing enabled, this step is automatic.

```bash
# Assume credentials for Spoke Account

# Get the resource share invitation ARN
export RESOURCE_SHARE_INVITATION_ARN=$(aws ram get-resource-share-invitations \
  --resource-share-arns ${RESOURCE_SHARE_ARN} \
  --region us-east-1 \
  --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
  --output text)

# Accept the invitation
aws ram accept-resource-share-invitation \
  --resource-share-invitation-arn ${RESOURCE_SHARE_INVITATION_ARN} \
  --region us-east-1
```

### Step 4: Deploy workloads (Spoke Account)

```bash
# Deploy in eu-west-1
aws cloudformation deploy \
  --stack-name multi-account-ireland \
  --template-file workloads.yaml \
  --parameter-overrides \
      CoreNetworkId="${CORENETWORK_ID}" \
      CoreNetworkArn="${CORENETWORK_ARN}" \
  --capabilities CAPABILITY_IAM \
  --region eu-west-1

# Deploy in us-east-1
aws cloudformation deploy \
  --stack-name multi-account-nvirginia \
  --template-file workloads.yaml \
  --parameter-overrides \
      CoreNetworkId="${CORENETWORK_ID}" \
      CoreNetworkArn="${CORENETWORK_ARN}" \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

> **Note**: EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Cleanup

### Step 1: Delete Workload stacks (Spoke Account)

```bash
# Assume credentials for Spoke Account

# Delete workload stacks
aws cloudformation delete-stack \
  --stack-name multi-account-ireland \
  --region eu-west-1

aws cloudformation delete-stack \
  --stack-name multi-account-nvirginia \
  --region us-east-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name multi-account-ireland \
  --region eu-west-1

aws cloudformation wait stack-delete-complete \
  --stack-name multi-account-nvirginia \
  --region us-east-1
```

### Step 2: Delete Core Network stack (Networking Account)

```bash
# Assume credentials for Networking Account

# Delete Core Network stack
aws cloudformation delete-stack \
  --stack-name core-network-multi-account \
  --region us-east-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name core-network-multi-account \
  --region us-east-1
```

## Next Steps

After successfully deploying this pattern:

1. **Explore the architecture**: Review segment associations and routing in Network Manager console
2. **Test connectivity**: Verify traffic flows match expected behavior
3. **Try modifications**: Add VPCs, change segments, update policies
4. **Advanced patterns**: Move to [Traffic inspection](../../3-traffic_inspection/) or [Routing policies](../../4-routing_policies/) patterns
