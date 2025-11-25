
## AWS Cloud WAN Blueprints - Routing policies (use cases)

Within this section of the blueprints, you will see different routing policy examples within Cloud WAN. The use cases covered are:

- [Filtering secondary CIDR blocks in VPC attachments](#filtering-secondary-cidr-blocks-in-vpc-attachments)

### Filtering secondary CIDR blocks in VPC attachments

Within this use case, we want to show how you can add filtering route policies in Cloud WAN at the attachment level. The use case is a common one we see in several architectures: VPCs have different VPC CIDR blocks, with one of them used only for internal traffic (think on cluster intra-VPC communication). This range, as it's intended to be internal, it's best to not propagate it to the network to avoid undesired routing behaviors.

The Core Network's policy creates the following resources:

* 2 [segments](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* and *development*. Core Network's policy includes an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*
* 1 [routing policy](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-route-policy.html) filtering any IPv4 CIDR block equals to 10.100.0.0/16 (our secondary CIDR block in the example). Direction of the rule is `inbound` (only option for policies to associate to VPC attachments).
* 1 [attachment policy rule](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-attachments.html) associating the routing policy defined to any attachment with the routing policy label `vpcAttachments`.

![Filtering-Secondary-Blocks](../../images/patterns_filtering_secondary_cidr_blocks.png)

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "dns-support": true,
    "security-group-referencing-support": true,
    "asn-ranges": [
      "65000-65003"
    ],
    "edge-locations": [
      {
        "location": "us-east-1",
        "asn": 65000
      },
      {
        "location": "eu-west-1",
        "asn": 65001
      }
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "and",
      "conditions": [
        {
          "type": "attachment-type",
          "operator": "equals",
          "value": "vpc"
        },
        {
          "type": "tag-exists",
          "key": "domain"
        }
      ],
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      }
    }
  ],
  "attachment-routing-policy-rules": [
    {
      "rule-number": 100,
      "conditions": [
        {
          "type": "routing-policy-label",
          "value": "vpcAttachments"
        }
      ],
      "action": {
        "associate-routing-policies": [
          "secondaryCidrFiltering"
        ]
      }
    }
  ],
  "routing-policies": [
    {
      "routing-policy-name": "secondaryCidrFiltering",
      "routing-policy-description": "Attachment IPv4 secondary CIDR block filtering",
      "routing-policy-direction": "inbound",
      "routing-policy-number": 100,
      "routing-policy-rules": [
        {
          "rule-number": 100,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-equals",
                "value": "10.100.0.0/16"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "drop"
            }
          }
        }
      ]
    }
  ]
}
```

