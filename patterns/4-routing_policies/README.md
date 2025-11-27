
## AWS Cloud WAN Blueprints - Routing policies (use cases)

Within this section of the blueprints, you will see different routing policy examples within Cloud WAN. The use cases covered are:

- [Filtering secondary CIDR blocks in VPC attachments](#filtering-secondary-cidr-blocks-in-vpc-attachments)
- [Creating IPv4 and IPv6 only segments through filtering](#creating-ipv4-and-ipv6-only-segments-through-filtering)
- [Filtering routes (hybrid environments) using BGP Communities](#filtering-routes-hybrid-environments-using-bgp-communities)

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

### Creating IPv4 and IPv6 only segments through filtering

Within this use case, we want to show how you can make use of the filtering capability in Cloud WAN when creating sharing between segments. As example, we are creating IPv4 and IPv6 only segments when sharing routes from segments with route tables including both IPv4 and IPv6 (dual-stack VPCs). 

The Core Network's policy creates the following resources:

* 4 [segments](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html):
  * 2 per routing domain - *production* and *development*. VPCs will be associated to these segments using an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*.
  * 2 segments for IPv4 (*ipv4only*) and IPv6 (*ipv6*) only routes - both *production* and *development* routes will be shared.
* 2 [routing policies](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-route-policy.html) filtering either any IPv4 (0.0.0.0/0) or IPv6 (::/0) CIDR blocks. These routing policies are configured as `inbound` - this is important as we want only the filtering to happen from *production* or *development* to the other segments (and not the other way around).
* 4 [share segment actions](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-actions-routes.html).
  * Between *ipv4only* and *production* / *development* - filtering any IPv6 route.
  * Between *ipv6only* and *production* / *development* - filtering any IPv4 route.

![IPv4-IPv6-segments](../../images/patterns_filtering_ipv4_ipv6_segments.png)

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
    },
    {
      "name": "ipv4only"
    },
    {
      "name": "ipv6only"
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
  "segment-actions": [
    {
      "action": "share",
      "mode": "attachment-route",
      "segment": "ipv4only",
      "share-with": ["production"],
      "routing-policy-names": ["filterIpv6"]
    },
    {
      "action": "share",
      "mode": "attachment-route",
      "segment": "ipv4only",
      "share-with": ["development"],
      "routing-policy-names": ["filterIpv6"]
    },
    {
      "action": "share",
      "mode": "attachment-route",
      "segment": "ipv6only",
      "share-with": ["production"],
      "routing-policy-names": ["filterIpv4"]
    },
    {
      "action": "share",
      "mode": "attachment-route",
      "segment": "ipv6only",
      "share-with": ["development"],
      "routing-policy-names": ["filterIpv4"]
    }
  ],
  "routing-policies": [
    {
      "routing-policy-name": "filterIpv4",
      "routing-policy-description": "Filtering all IPv4 ranges",
      "routing-policy-direction": "inbound",
      "routing-policy-number": 100,
      "routing-policy-rules": [
        {
          "rule-number": 100,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-in-cidr",
                "value": "0.0.0.0/0"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "drop"
            }
          }
        }
      ]
    },
    {
      "routing-policy-name": "filterIpv6",
      "routing-policy-description": "Filtering all IPv6 ranges",
      "routing-policy-direction": "inbound",
      "routing-policy-number": 200,
      "routing-policy-rules": [
        {
          "rule-number": 100,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-in-cidr",
                "value": "::/0"
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

### Filtering routes (hybrid environments) using BGP Communities

> **Note:** For an end-to-end testing of this use case, you need to build the hybrid connectivity to the Core Network. You will need either a **site-to-site-vpn** or **connect** attachment. Check the use case's explanation below to understand the BGP configuration needed.

Within this use case, we want to show how you can make use of the filtering capability in Cloud WAN to create traffic segmentation at the routing level while you can announce all your on-prem routes using the same BGP session. 

The idea is that you tag each routing domain's routes by using different BGP communities. In Cloud WAN, you can then filter those routes to different segments depending those BGP communities.

The Core Network's policy creates the following resources:

* 3 [segments](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html):
  * 2 for routing domain - *development* and *test*. VPCs will be associated to these segments using an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*.
  * 1 *hybrid* segment, where your hybrid connectivity attachments will be associated. An attachment policy rule will make sure that any **site-to-site-vpn** or **connect** attachment is associated to this segment.
* 2 [routing policies](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-route-policy.html) doing a similar action: filter all the routes (outbound direction) except the ones tagged with the configured BGP Community (each policy is configured with a different value). **Feel free to adapt the BGP communities configured to your use case**. 
  * (rule 100) Allowing any traffic coming from the specified BGP Community.
  * (rule 200) Blocking any IPv4 range under 0.0.0.0/0.
  * (rule 300) Blocking the 0.0.0.0/0 route.
* 2 [share segment actions](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-actions-routes.html). Each share segment action is configured with the correponding route policy.
  * Between *hybrid* and *development*.
  * Between *hybrid* and *test*.

![Filtering-BGP-Community](../../images/patterns_filtering_bgp_community.png.png)

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
      "name": "development",
      "require-attachment-acceptance": false
    },
    {
      "name": "test",
      "require-attachment-acceptance": false
    },
    {
      "name": "hybrid",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "share",
      "mode": "attachment-route",
      "segment": "hybrid",
      "share-with": [
        "development"
      ],
      "routing-policy-names": [
        "filterDevelopmentRoutes"
      ]
    },
    {
      "action": "share",
      "mode": "attachment-route",
      "segment": "hybrid",
      "share-with": [
        "test"
      ],
      "routing-policy-names": [
        "filterTestRoutes"
      ]
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
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "attachment-type",
          "operator": "equals",
          "value": "site-to-site-vpn"
        },
        {
          "type": "attachment-type",
          "operator": "equals",
          "value": "connect"
        }
      ],
      "action": {
        "association-method": "constant",
        "segment": "hybrid"
      }
    }
  ],
  "routing-policies": [
    {
      "routing-policy-name": "filterTestRoutes",
      "routing-policy-direction": "outbound",
      "routing-policy-number": 100,
      "routing-policy-rules": [
        {
          "rule-number": 100,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "community-in-list",
                "value": "65051:100"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "allow"
            }
          }
        },
        {
          "rule-number": 200,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-in-cidr",
                "value": "0.0.0.0/0"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "drop"
            }
          }
        },
        {
          "rule-number": 300,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-equals",
                "value": "0.0.0.0/0"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "drop"
            }
          }
        }
      ]
    },
    {
      "routing-policy-name": "filterDevelopmentRoutes",
      "routing-policy-direction": "outbound",
      "routing-policy-number": 200,
      "routing-policy-rules": [
        {
          "rule-number": 100,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "community-in-list",
                "value": "65052:100"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "allow"
            }
          }
        },
        {
          "rule-number": 200,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-in-cidr",
                "value": "0.0.0.0/0"
              }
            ],
            "condition-logic": "or",
            "action": {
              "type": "drop"
            }
          }
        },
        {
          "rule-number": 300,
          "rule-definition": {
            "match-conditions": [
              {
                "type": "prefix-equals",
                "value": "0.0.0.0/0"
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
