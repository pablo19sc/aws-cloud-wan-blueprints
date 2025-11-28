# AWS Cloud WAN Blueprints - Traffic Inspection architectures

## Overview

This section demonstrates various traffic inspection patterns with AWS Cloud WAN, showing how to implement centralized security controls for egress and east-west traffic flows. These patterns use AWS Network Firewall for inspection, though the concepts apply to any network security appliance.

**Use these patterns to**:

- Implement centralized egress (north-south) traffic inspection
- Enable east-west traffic inspection between VPCs
- Understand single-hop vs dual-hop inspection modes
- Integrate Cloud WAN with Transit Gateway for hybrid inspection
- Design multi-region security architectures

## Common architecture elements

| Element | Configuration |
|---------|---------------|
| **Segments** | `production` (isolated), `development` (non-isolated) |
| **Network Function Group** | `inspectionVpcs` for firewall VPCs |
| **Inspection Requirements** | Production intra-segment, inter-segment, egress traffic |

### Firewall Policy Configuration

> **Note**: This repository focuses on Cloud WAN configuration, not firewall policy details. The AWS Network Firewall policies configured are simple and for testing only.

**Egress Traffic**:

- Allow traffic to `*.amazon.com` domains only
- Block all other internet-bound traffic

**East-West Traffic**:

- Alert and allow all ICMP packets
- Use for connectivity testing

---

## Inspection Patterns

| Pattern | Description | Inspection Type | IaC Support |
|---------|-------------|-----------------|-------------|
| [1. Centralized Outbound](#1-centralized-outbound) | Egress inspection in all regions | North-South | Terraform, CloudFormation |
| [2. Centralized Outbound (Region Without Inspection)](#2-centralized-outbound-region-without-inspection) | Egress inspection with remote region routing | North-South | Terraform, CloudFormation |
| [3. East-West (Dual-Hop)](#3-east-west-dual-hop) | Cross-region traffic inspected in both regions | East-West | Terraform, CloudFormation |
| [4. East-West (Single-Hop)](#4-east-west-single-hop) | Cross-region traffic inspected in one region | East-West | Terraform, CloudFormation |
| [5. East-West with TGW (Dual-Hop)](#5-east-west-with-transit-gateway-dual-hop) | TGW spoke VPCs with dual-hop inspection | East-West + TGW | Terraform |
| [6. East-West with TGW (Single-Hop)](#6-east-west-with-transit-gateway-single-hop) | TGW spoke VPCs with single-hop inspection | East-West + TGW | Terraform, CloudFormation |

---

## 1. Centralized Outbound

Inspects all egress (internet-bound) traffic from spoke VPCs through centralized inspection VPCs in each region.

![Centralized Outbound](../../images/centralizedOutbound.png)

### Key Components

| Component | Configuration |
|-----------|---------------|
| **Regions** | us-east-1, eu-west-1, ap-southeast-2 |
| **Service Insertion** | `send-to` action for default routes (0.0.0.0/0, ::/0) |

### Traffic Flow

| Source | Destination | Result | Inspection | Reason |
|--------|-------------|--------|------------|--------|
| Production VPC A | Production VPC B | ❌ Blocked | N/A | `production` segment is isolated |
| Development VPC A | Development VPC B | ✅ Allowed | ❌ No | `development` segment allows intra-segment traffic |
| Production VPC | Development VPC | ❌ Blocked | N/A | No segment sharing |
| Production VPC | Internet | ✅ Allowed | 🔒 Yes | `send-to` action routes to inspection VPC |
| Development VPC | Internet | ✅ Allowed | 🔒 Yes | `send-to` action routes to inspection VPC |

### Implementation

| IaC Tool | Location |
|----------|----------|
| **CloudFormation** | [`./1-centralized_outbound/cloudformation/`](./1-centralized_outbound/cloudformation/) |
| **Terraform** | [`./1-centralized_outbound/terraform/`](./1-centralized_outbound/terraform/) |

<details>
<summary>View Network Policy</summary>

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": ["64520-65525"],
    "edge-locations": [
      {"location": "eu-west-1"},
      {"location": "us-east-1"},
      {"location": "ap-southeast-2"}
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "production",
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      }
    },
    {
      "action": "send-to",
      "segment": "development",
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
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
  ]
}
```
</details>

---

## 2. Centralized Outbound (Region Without Inspection)

Inspects all egress (internet-bound) traffic from spoke VPCs through centralized inspection VPCs in each region. In addition, it demonstrates how to route traffic from regions without local inspection VPCs to the nearest region with inspection capabilities.

![Centralized Outbound - Region Without Inspection](../../images/centralizedOutbound_regionWithoutInspection.png)

### Key Components

| Component | Configuration |
|-----------|---------------|
| **Regions** | us-east-1, eu-west-1, eu-west-2 (no inspection), ap-southeast-2 |
| **Service Insertion** | `send-to` with `with-edge-overrides` |
| **Edge Override** | eu-west-2 traffic → eu-west-1 inspection |

### Traffic Flow

| Source | Destination | Result | Inspection | Reason |
|--------|-------------|--------|------------|--------|
| Production VPC A | Production VPC B | ❌ Blocked | N/A | `production` segment is isolated |
| Development VPC A | Development VPC B | ✅ Allowed | ❌ No | `development` segment allows intra-segment traffic |
| Production VPC | Development VPC | ❌ Blocked | N/A | No segment sharing |
| VPC (eu-west-1) | Internet | ✅ Allowed | 🔒 Yes (local) | Inspected in eu-west-1 |
| VPC (us-east-1) | Internet | ✅ Allowed | 🔒 Yes (local) | Inspected in us-east-1 |
| VPC (ap-southeast-2) | Internet | ✅ Allowed | 🔒 Yes (local) | Inspected in ap-southeast-2 |
| VPC (eu-west-2) | Internet | ✅ Allowed | 🔒 Yes (remote) | Routed to eu-west-1 for inspection |

### Implementation

| IaC Tool | Location |
|----------|----------|
| **CloudFormation** | [`./2-centralized_outbound_region_without_inspection/cloudformation/`](./2-centralized_outbound_region_without_inspection/cloudformation/) |
| **Terraform** | [`./2-centralized_outbound_region_without_inspection/terraform/`](./2-centralized_outbound_region_without_inspection/terraform/) |

<details>
<summary>View Network Policy</summary>

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": ["64520-65525"],
    "edge-locations": [
      {"location": "eu-west-1"},
      {"location": "eu-west-2"},
      {"location": "us-east-1"},
      {"location": "ap-southeast-2"}
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "production",
      "via": {
        "network-function-groups": ["inspectionVpcs"],
        "with-edge-overrides": [
          {
            "edge-sets": [["eu-west-2"]],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    },
    {
      "action": "send-to",
      "segment": "development",
      "via": {
        "network-function-groups": ["inspectionVpcs"],
        "with-edge-overrides": [
          {
            "edge-sets": [["eu-west-2"]],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
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
  ]
}
```
</details>

---

## 3. East-West (Dual-Hop)

Inspects traffic between VPCs (east-west) with dual-hop mode: cross-region traffic is inspected in both source and destination regions.

![East-West Dual-Hop](../../images/east_west_dualhop.png)

### Key Components

| Component | Configuration |
|-----------|---------------|
| **Regions** | us-east-1, eu-west-1, ap-southeast-2 |
| **Service Insertion** | `send-via` with `mode: dual-hop` |

### Traffic Flow

| Source | Destination | Result | Inspection | Reason |
|--------|-------------|--------|------------|--------|
| Production VPC A (same region) | Production VPC B (same region) | ✅ Allowed | 🔒 Yes | Intra-segment inspection via `send-via` |
| Production VPC (us-east-1) | Production VPC (eu-west-1) | ✅ Allowed | 🔒🔒 Yes (dual) | Inspected in both us-east-1 and eu-west-1 |
| Production VPC | Development VPC (same region) | ✅ Allowed | 🔒 Yes | Inter-segment inspection via `send-via` |
| Production VPC (us-east-1) | Development VPC (eu-west-1) | ✅ Allowed | 🔒🔒 Yes (dual) | Inspected in both us-east-1 and eu-west-1 |
| Development VPC A | Development VPC B | ✅ Allowed | ❌ No | `development` segment allows direct traffic |

### Implementation

| IaC Tool | Location |
|----------|----------|
| **CloudFormation** | [`./3-east_west_dualhop/cloudformation/`](./3-east_west_dualhop/cloudformation/) |
| **Terraform** | [`./3-east_west_dualhop/terraform/`](./3-east_west_dualhop/terraform/) |

<details>
<summary>View Network Policy</summary>

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": ["64520-65525"],
    "edge-locations": [
      {"location": "eu-west-1"},
      {"location": "us-east-1"},
      {"location": "ap-southeast-2"}
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-via",
      "segment": "production",
      "mode": "dual-hop",
      "when-sent-to": {
        "segments": "*"
      },
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
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
  ]
}
```
</details>

---

## 4. East-West (Single-Hop)

Inspects east-west traffic with single-hop mode: cross-region traffic is inspected in only one region.

![East-West Single-Hop](../../images/east_west_singlehop.png)

### Key Components

| Component | Configuration |
|-----------|---------------|
| **Regions** | us-east-1, eu-west-1, eu-west-2 (no inspection), ap-southeast-2 |
| **Service Insertion** | `send-via` with `mode: single-hop` |
| **Edge Overrides** | Define which region inspects traffic between region pairs |

### Traffic Flow

| Source | Destination | Result | Inspection | Reason |
|--------|-------------|--------|------------|--------|
| Production VPC A (same region) | Production VPC B (same region) | ✅ Allowed | 🔒 Yes | Intra-segment inspection via `send-via` |
| Production VPC (us-east-1) | Production VPC (eu-west-1) | ✅ Allowed | 🔒 Yes (single) | Inspected in us-east-1 only (per matrix) |
| Production VPC (eu-west-2) | Production VPC (eu-west-1) | ✅ Allowed | 🔒 Yes (single) | Inspected in eu-west-1 (no local inspection) |
| Production VPC | Development VPC (same region) | ✅ Allowed | 🔒 Yes | Inter-segment inspection via `send-via` |
| Production VPC (us-east-1) | Development VPC (eu-west-1) | ✅ Allowed | 🔒 Yes (single) | Inspected in us-east-1 only (per matrix) |
| Development VPC A | Development VPC B | ✅ Allowed | ❌ No | `development` segment allows direct traffic |

### Inspection Matrix

| Source / Destination | us-east-1 | eu-west-1 | eu-west-2 | ap-southeast-2 |
|---------------------|-----------|-----------|-----------|----------------|
| **us-east-1** | us-east-1 | us-east-1 | us-east-1 | us-east-1 |
| **eu-west-1** | us-east-1 | eu-west-1 | eu-west-1 | eu-west-1 |
| **eu-west-2** | us-east-1 | eu-west-1 | eu-west-1 | ap-southeast-2 |
| **ap-southeast-2** | us-east-1 | eu-west-1 | ap-southeast-2 | ap-southeast-2 |

### Implementation

| IaC Tool | Location |
|----------|----------|
| **CloudFormation** | [`./4-east_west_singlehop/cloudformation/`](./4-east_west_singlehop/cloudformation/) |
| **Terraform** | [`./4-east_west_singlehop/terraform/`](./4-east_west_singlehop/terraform/) |

<details>
<summary>View Network Policy</summary>

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": ["64520-65525"],
    "edge-locations": [
      {"location": "eu-west-1"},
      {"location": "eu-west-2"},
      {"location": "us-east-1"},
      {"location": "ap-southeast-2"}
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-via",
      "segment": "production",
      "mode": "single-hop",
      "when-sent-to": {
        "segments": "*"
      },
      "via": {
        "network-function-groups": ["inspectionVpcs"],
        "with-edge-overrides": [
          {
            "edge-sets": [["us-east-1", "eu-west-1"]],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [["us-east-1", "ap-southeast-2"]],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [["ap-southeast-2", "eu-west-1"]],
            "use-edge-location": "eu-west-1"
          },
          {
            "edge-sets": [["eu-west-2", "eu-west-1"]],
            "use-edge-location": "eu-west-1"
          },
          {
            "edge-sets": [["eu-west-2", "us-east-1"]],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [["ap-southeast-2", "eu-west-2"]],
            "use-edge-location": "ap-southeast-2"
          },
          {
            "edge-sets": [["eu-west-2"]],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
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
  ]
}
```
</details>

---

## 5. East-West with Transit Gateway (Dual-Hop)

Spoke VPCs attach to Transit Gateway, which then peers with Cloud WAN. Uses separate inspection VPCs for intra-region (TGW) and inter-region (Cloud WAN) traffic. **Why two sets of Inspection VPCs?**

1. **TGW Inspection VPCs**: Handle intra-region traffic between segments
2. **Cloud WAN Inspection VPCs**: Handle inter-region traffic

![East-West TGW Dual-Hop](../../images/east_west_tgw_spokeVpcs_dualhop.png)

### Key Components

| Component | Configuration |
|-----------|---------------|
| **Regions** | us-east-1, eu-west-1, ap-southeast-2 |
| **Spoke VPC Attachment** | Transit Gateway (not direct to Cloud WAN) |
| **TGW Route Tables** | `production`, `development`, `prod_routes`, `post_inspection` |
| **Inspection VPCs** | Separate for TGW (intra-region) and Cloud WAN (inter-region) |
| **Service Insertion** | `send-via` dual-hop for inter-region |

### Traffic Flow

| Source | Destination | Result | Inspection | Reason |
|--------|-------------|--------|------------|--------|
| Production VPC A (same region) | Production VPC B (same region) | ✅ Allowed | 🔒 Yes (TGW) | Intra-region via TGW inspection VPC |
| Production VPC (us-east-1) | Production VPC (eu-west-1) | ✅ Allowed | 🔒🔒 Yes (dual) | Inter-region via Cloud WAN (dual-hop) |
| Production VPC | Development VPC (same region) | ✅ Allowed | 🔒 Yes (TGW) | Inter-segment via TGW inspection VPC |
| Production VPC (us-east-1) | Development VPC (eu-west-1) | ✅ Allowed | 🔒🔒 Yes (dual) | Inter-region via Cloud WAN (dual-hop) |
| Development VPC A | Development VPC B (same region) | ✅ Allowed | ❌ No | `development` TGW route table allows direct |
| Development VPC (us-east-1) | Development VPC (eu-west-1) | ✅ Allowed | ❌ No | `development` segment allows direct |

### Implementation

| IaC Tool | Location |
|----------|----------|
| **Terraform** | [`./5-east_west_tgw_spoke_vpcs_dualhop/terraform/`](./5-east_west_tgw_spoke_vpcs_dualhop/terraform/) |

<details>
<summary>View Network Policy</summary>

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "asn-ranges": ["64520-65525"],
    "edge-locations": [
      {"location": "eu-west-1"},
      {"location": "us-east-1"},
      {"location": "ap-southeast-2"}
    ],
    "vpn-ecmp-support": false
  },
  "segments": [
    {
      "isolate-attachments": false,
      "name": "development",
      "require-attachment-acceptance": false
    },
    {
      "isolate-attachments": true,
      "name": "production",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-via",
      "mode": "dual-hop",
      "segment": "production",
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      },
      "when-sent-to": {
        "segments": ["development"]
      }
    },
    {
      "action": "send-via",
      "mode": "dual-hop",
      "segment": "production",
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      },
      "when-sent-to": {
        "segments": "production"
      }
    }
  ],
  "attachment-policies": [
    {
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      },
      "condition-logic": "or",
      "conditions": [
        {
          "key": "inspection",
          "operator": "equals",
          "type": "tag-value",
          "value": "true"
        }
      ],
      "rule-number": 100
    },
    {
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      },
      "condition-logic": "or",
      "conditions": [
        {
          "key": "domain",
          "type": "tag-exists"
        }
      ],
      "rule-number": 200
    }
  ]
}
```
</details>

---

## 6. East-West with Transit Gateway (Single-Hop)

Spoke VPCs attach to Transit Gateway, which then peers with Cloud WAN. This pattern uses single-hop inspection for inter-region traffic and combines `send-to` and `send-via` actions.

![East-West TGW Single-Hop](../../images/east_west_tgw_spokeVpcs_singlehop.png)

### Key Components

| Component | Configuration |
|-----------|---------------|
| **Regions** | us-east-1, eu-west-1, ap-southeast-2 |
| **Spoke VPC Attachment** | Transit Gateway (not direct to Cloud WAN) |
| **TGW Route Tables** | `production`, `development`, `prod_routes` |
| **Service Insertion** | `send-to` (intra-region) + `send-via` single-hop (inter-region) |
| **Inspection** | Single-hop for inter-region, Cloud WAN for intra-region |

### Traffic Flow

| Source | Destination | Result | Inspection | Reason |
|--------|-------------|--------|------------|--------|
| Production VPC A (same region) | Production VPC B (same region) | ✅ Allowed | 🔒 Yes (Cloud WAN) | Intra-region via Cloud WAN `send-to` |
| Production VPC (us-east-1) | Production VPC (eu-west-1) | ✅ Allowed | 🔒 Yes (single) | Inter-region via Cloud WAN (single-hop) |
| Production VPC | Development VPC (same region) | ✅ Allowed | 🔒 Yes (Cloud WAN) | Inter-segment via Cloud WAN `send-to` |
| Production VPC (us-east-1) | Development VPC (eu-west-1) | ✅ Allowed | 🔒 Yes (single) | Inter-region via Cloud WAN (single-hop) |
| Development VPC A | Development VPC B (same region) | ✅ Allowed | ❌ No | `development` TGW route table allows direct |
| Development VPC (us-east-1) | Development VPC (eu-west-1) | ✅ Allowed | ❌ No | `development` segment allows direct |

### Implementation

| IaC Tool | Location |
|----------|----------|
| **CloudFormation** | [`./6-east_west_tgw_spoke_vpcs_singlehop/cloudformation/`](./6-east_west_tgw_spoke_vpcs_singlehop/cloudformation/) |
| **Terraform** | [`./6-east_west_tgw_spoke_vpcs_singlehop/terraform/`](./6-east_west_tgw_spoke_vpcs_singlehop/terraform/) |

<details>
<summary>View Network Policy</summary>

```json
{
  "version": "2025.11",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": ["64520-65525"],
    "edge-locations": [
      {"location": "eu-west-1"},
      {"location": "us-east-1"},
      {"location": "ap-southeast-2"}
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "production",
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      }
    },
    {
      "action": "send-to",
      "segment": "development",
      "via": {
        "network-function-groups": ["inspectionVpcs"]
      }
    },
    {
      "action": "send-via",
      "segment": "production",
      "mode": "single-hop",
      "when-sent-to": {
        "segments": "*"
      },
      "via": {
        "network-function-groups": ["inspectionVpcs"],
        "with-edge-overrides": [
          {
            "edge-sets": [["us-east-1", "eu-west-1"]],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [["us-east-1", "ap-southeast-2"]],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [["ap-southeast-2", "eu-west-1"]],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
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
  ]
}
```
</details>

---

## Testing Connectivity

### 1. Verify Attachments

Check that inspection VPCs are associated with the NFG and spoke VPCs with segments.

### 2. Test Egress Traffic (patterns 1 & 2)

```bash
# From spoke VPC instance
curl https://www.amazon.com
# Should succeed (allowed by firewall policy)

curl https://www.nytimes.com
# Should fail (blocked by firewall policy)
```

### 3. Test East-West Traffic (patterns 3 to 6)

**Intra-Segment (Production to Production)**:

```bash
# From production VPC A to production VPC B (same region)
ping <production-vpc-b-ip>
# Should work (ICMP allowed by firewall policy, inspected)

# From production VPC in us-east-1 to production VPC in eu-west-1
ping <production-vpc-ip-in-eu-west-1>
# Should work (ICMP allowed by firewall policy, inspected)
```

```bash
# From development VPC A to development VPC B (same region)
ping <development-vpc-b-ip>
# Should work (development segment allows direct traffic, no inspection)

# From development VPC in us-east-1 to development VPC in eu-west-1
ping <development-vpc-ip-in-eu-west-1>
# Should work (development segment allows direct traffic, no inspection)
```

**Inter-Segment (Production to Development)**:

```bash
# From production VPC to development VPC (same region)
ping <development-vpc-ip>
# Should work (send-via enables inspection)

# From production VPC in us-east-1 to development VPC in eu-west-1
ping <development-vpc-ip-in-eu-west-1>
# Should work (send-via enables inspection)
```

### 4. Verify Inspection

Check AWS Network Firewall logs to confirm traffic is being inspected.
