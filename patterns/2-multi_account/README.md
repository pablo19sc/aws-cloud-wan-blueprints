
## AWS Cloud WAN Blueprints - Multi-AWS Account environment

Within this section of the blueprints, we want to provide an example on how AWS Cloud WAN works in multi-AWS Account environments. The code provided will suppose the following two AWS Account types:

- **Networking AWS Account**. Central AWS Account where Cloud WAN's core network is built. The following resources are built within this account:
    - Global network and core network. The core network policy builds the following global network:
        - Two AWS Regions, two [segments](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html). The *production* segment is isolated, meaning that VPCs within this segment won't be able to talk between each other. The *development* segment allows communication between VPCs within the segment.
        - One [attachment policies](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-attachments.html) checking that attachments are coming from the spoke AWS Account, they are type VPC, and that the tag with a key `domain` exists. If all the conditions are met, it will check the value of the tag `domain`, and it will associate the attachment to a segment with the same name.
    - [AWS Resource Access Manager](https://aws.amazon.com/ram/) (RAM) resource share. The core network is shared with the spoke AWS Account.
- **Spoke AWS Account**. Any AWS Account that wants to connect their workloads to Cloud WAN. The following resources are built within this account:
    - This examples supposes that Networking and Spoke AWS Accounts are not in the same [AWS Organization](https://aws.amazon.com/organizations/), therefore the RAM resource share must be accepted. Check the [documentation](https://docs.aws.amazon.com/organizations/latest/userguide/services-that-can-integrate-ram.html) for more information how RAM works with AWS Organizations.
    - Spoke VPCs and compute resources (EC2 instances and EC2 instance connect endpoint). Cloud WAN's VPC attachments are created with the corresponding tags - these tags are passed to the Networking Account by the service to automate association (from attachment policies).

**Note** that given the core network is a global resource, this sharing must be done from the N. Virginia (us-east-1) Region - check the [documentation](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-share-network.html) for more information.

![Multi-Account Architecture](../../images/patterns_multi_account.png)

```json
{
  "version": "2021.12",
  "core-network-configuration": {
    "vpn-ecmp-support": false,
    "asn-ranges": [
      "64520-65525"
    ],
    "edge-locations": [
      {
        "location": "eu-west-1"
      },
      {
        "location": "us-east-1"
      }
    ]
  },
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "and",
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      },
      "conditions": [
        {
          "type": "tag-exists",
          "key": "domain"
        },
        {
          "type": "attachment-type",
          "value": "vpc",
          "operator": "equals"
        },
        {
          "type": "account-id",
          "value": "225963075789",
          "operator": "equals"
        }
      ]
    }
  ],
  "segments": [
    {
      "isolate-attachments": true,
      "name": "production",
      "require-attachment-acceptance": false
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ]
}
```
