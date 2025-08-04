# AWS Cloud WAN Blueprints - Traffic Inspection architectures (Centralized Outbound & East-West single-hop)

This example shows a centralized east-west inspection architecture. The core network policy builds the following network:

* 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*
* 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
* **Service Insertion rules**: 
    * One [send-via](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#cloudwan-policy-service-insertion-modes) action to inspect the traffic between VPCs in the *production* segment, and between the *production* and *development* segments. This example makes use of the **single-hop** mode - traffic traversing two AWS Regions is inspected in only one of them.
    * In each routing domain's segment, a [send-to](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#cloudwan-policy-service-insertion-modes) action is created to send the default traffic (0.0.0.0/0 and ::/0) to the inspection VPCs.

![Centralized Outbound & East-West single-hop](../../../images/patterns_outbound_eastwest_singlehop.png)

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
      },
      {
        "location": "us-west-2"
      }
    ]
  },
  "attachment-policies": [
    {
      "rule-number": 100,
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      },
      "conditions": [
        {
          "type": "tag-value",
          "value": "true",
          "operator": "equals",
          "key": "inspection"
        }
      ]
    },
    {
      "rule-number": 200,
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      },
      "conditions": [
        {
          "type": "tag-exists",
          "key": "domain"
        }
      ]
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
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
  ],
  "segment-actions": [
    {
      "mode": "single-hop",
      "segment": "production",
      "action": "send-via",
      "via": {
        "with-edge-overrides": [
          {
            "edge-sets": [
              [
                "eu-west-1",
                "us-east-1"
              ],
              [
                "eu-west-1",
                "us-west-2"
              ]
            ],
            "use-edge-location": "eu-west-1"
          },
          {
            "edge-sets": [
              [
                "us-west-2",
                "us-east-1"
              ]
            ],
            "use-edge-location": "us-east-1"
          }
        ],
        "network-function-groups": [
          "inspectionVpcs"
        ]
      },
      "when-sent-to": {
        "segments": "production"
      }
    },
    {
      "segment": "production",
      "action": "send-to",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ]
      },
      "when-sent-to": {
        "segments": "production"
      }
    },
    {
      "segment": "development",
      "action": "send-to",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ]
      },
      "when-sent-to": {
        "segments": "development"
      }
    }
  ]
}
```