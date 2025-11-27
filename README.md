# AWS Cloud WAN Blueprints

Welcome to AWS Cloud WAN Blueprints!

This project contains a collection of AWS Cloud WAN patterns implemented in [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) and [Terraform](https://developer.hashicorp.com/terraform) that demonstrate how to configure and deploy global networks using [AWS Cloud WAN](https://aws.amazon.com/cloud-wan/).

## Motivation

AWS Cloud WAN simplifies the configuration and management of global networks by providing a centralized, policy-driven approach to building multi-region connectivity. While Cloud WAN abstracts away much of the complexity of traditional AWS networking (such as manual Transit Gateway peering, static routing, or associations and propagations), understanding all the service's capabilities can be overwhelming, especially when designing production-grade architectures.

AWS customers have asked for practical examples and best practices that demonstrate how to leverage Cloud WAN's full potential. These blueprints provide real-world use cases with complete, tested implementations that teams can use for:

- **Proof of Concepts (PoCs)**: Quickly validate Cloud WAN capabilities in your environment.
- **Testing and learning**: Understand how different features work together through hands-on examples.
- **Starting point**: Use as a foundation for your production network configurations.
- **Best practices**: Learn recommended patterns for common networking scenarios.

With Cloud WAN Blueprints, customers can configure and deploy purpose-built global networks and start onboarding workloads in days, rather than spending weeks or months figuring out the optimal configuration.

## Consumption

AWS Cloud WAN Blueprints have been designed to be consumed in the following manners:

1. **Reference**: Users can refer to the patterns and snippets provided to help guide them to their desired solution. Users will typically view how the pattern or snippet is configured to achieve the desired end result and then replicate that in their environment.

2. **Copy & Paste**: Users can copy and paste the patterns and snippets into their own environment, using Cloud WAN Blueprints as the starting point for their implementation. Users can then adapt the initial pattern to customize it to their specific needs.

**AWS Cloud WAN Blueprints are not intended to be consumed as-is directly from this project**. The patterns provided only contain `variables` when certain information is required to deploy the pattern and generally use local variables. If you wish to deploy the patterns into a different AWS Region or with other changes, it is recommended that you make those modifications locally before applying the pattern.

## Patterns

| Pattern | Description | IaC Support |
|---------|-------------|-------------|
| [1. Simple Architecture](./patterns/1-simple_architecture/) | Basic Cloud WAN setup with segments and attachment policies | Terraform, CloudFormation |
| [2. Multi-AWS Account](./patterns/2-multi_account/) | Cross-account Cloud WAN deployment with AWS RAM sharing | Terraform, CloudFormation |
| [3. Traffic Inspection](./patterns/3-traffic_inspection/) | Various inspection architectures (centralized outbound, east-west) | Terraform, CloudFormation |
| [4. Routing Policies](./patterns/4-routing_policies/) | Advanced routing controls, filtering, and BGP manipulation | Terraform, CloudFormation |
| 5. Hybrid Architectures | On-premises integration patterns with Site-to-Site VPN and Direct Connect | Coming Soon |

## Infrastructure as Code Considerations

AWS Cloud WAN Blueprints do not intend to teach users the recommended practices for Infrastructure as Code (IaC) tools nor does it offer guidance on how users should structure their IaC projects. The patterns provided are intended to show users how they can achieve a defined architecture or configuration in a way that they can quickly and easily get up and running to start interacting with that pattern. Therefore, there are a few considerations users should be aware of when using Cloud WAN Blueprints:

1. We recognize that most users will already have existing VPCs in separate IaC projects or stacks. However, the patterns provided come complete with VPCs to ensure stable, deployable examples that have been tested and validated.

2. Patterns are not intended to be consumed in-place in the same manner that one would consume a reusable module. Therefore, we do not provide extensive parameters and outputs to expose various levels of configuration for the examples. Users can modify the pattern locally after cloning to suit their requirements.

3. The patterns use local variables (Terraform) or parameters (CloudFormation) with sensible defaults. If you wish to deploy patterns into different regions or with other changes, modify these values before deploying.

4. For production deployments, we recommend separating your infrastructure into multiple projects or stacks (e.g., network infrastructure, workload VPCs, inspection resources) to follow IaC best practices and enable independent lifecycle management.

## AWS Cloud WAN Fundamentals

### Architecture Overview

[AWS Cloud WAN](https://docs.aws.amazon.com/network-manager/latest/cloudwan/what-is-cloudwan.html) is a managed, intent-driven service for building and managing global networks across [AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/) and on-premises environments.

**Key Advantages**:

- Automates cross-region dynamic routing, and eliminates static routing between regions.
- Provides centralized network segmentation and configuration management.
- Simplifies global network operations.
- Provides capabilities to create advanced routing scenarios configured from AWS side.

### Core Components

#### 1. Control plane & Network policy

**Management**: Centralized through AWS Network Manager. [Home Region](https://docs.aws.amazon.com/network-manager/latest/cloudwan/what-is-cloudwan.html#cloudwan-home-region) is Oregon (us-west-2).

**Network Policy**: Declarative JSON document defining:

- Segments (routing domains).
- Routing behavior.
- Attachment-to-segment mappings.
- Access control and traffic routing intent.

This policy-driven approach automates underlying network configuration while ensuring scalability and consistency across AWS Regions.

#### 2. Core Network Edge (CNE)

**Function**: Regional router (similar to Transit Gateway). High-available and resilient, deployed in each AWS Region where you want Cloud WAN to operate.

**Characteristics**:

- Automatic full-mesh peering between CNEs.
- Dynamic routing (e-BGP) for route exchange.

#### 3. Segments

**Definition**: Global route table (similar to Transit Gateway route table or VRF domain)

**Characteristics**:

- Available in every Region with a CNE.
- Can be limited to specific Regions.
- Attachments only possible in Regions where segment exists.

**Common Segmentation Patterns**:

1. By environment (dev, test, staging, prod, hybrid)
2. By business unit (Org A, Org B, Org C)
3. By geography (North America, LATAM, Europe, APAC)

**Default Behavior**:

- Attachments auto-propagate prefixes to their segment.
- Intra-segment traffic allowed by default.

**Important differences from VRFs**:

- Support isolated/non-isolated attachments.
- No overlapping prefixes allowed.

#### 4. Routing Actions

##### Segment Sharing

Exchange routes between segments (1:1 or 1:many) without inspection. Non-transitive - requires explicit share action between segments.

##### Service Insertion

Defines inspection for:

- Intra-segment traffic (isolated segments).
- Inter-segment traffic.
- Egress traffic.

**Implementation**:

- Inspection VPCs attached to Network Function Groups (NFGs).
- NFGs act as managed security segments.
- Support cross-region inspection.
- Multiple NFGs supported for firewall grouping.

**Actions**:

- `send-via`: East-west traffic inspection (intra/inter-segment).
- `send-to`: Egress traffic inspection.

##### Routing Policies

Fine-grained routing controls for:

**Route Filtering**: Drop routes from propagations based on prefixes, prefix lists, or BGP communities.

**Route Summarization**: Aggregate routes outbound on attachments.

**Path Preferences**: Influence traffic paths via BGP attributes (Local Preference, AS-PATH, MED).

**BGP Communities**: Transitively pass, match, and act on BGP communities.

[See AWS documentation for considerations](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-routing-policies.html#cloudwan-routing-policies-considerations)

#### 5. Attachments

**Definition**: Connection between network resource and CNEs.

**Types**:

1. VPC
2. Site-to-Site VPN
3. Direct Connect Gateway
4. Transit Gateway Route Table - Integrate existing Transit Gateways
5. Connect - SD-WAN integration via:
   - GRE (Generic Routing Encapsulation)
   - Tunnel-less Connect (No Encapsulation)

**Note**: Connect attachments require underlay (transport) VPC attachment.

**Constraints**: Attachment can only be associated to one segment.

#### 6. Attachment Policies

**Purpose**: Rules governing attachment-to-segment/NFG association.

**Matching Attributes**:

- Attachment tags
- Attachment type
- AWS Account ID
- AWS Region

**NFG Association**: Tags only

**Require acceptance feature**:

- Default: Auto-accept.
- Optional: Manual approval required.
- Recommended for sensitive workloads (especially without isolated attachments).
- Pending attachments cannot access core network until approved.

## Prerequisites

Before using these blueprints, you should have:

- **AWS Networking Knowledge**: Understanding of VPCs, subnets, route tables, Transit Gateways, and Direct Connect.
- **General Networking Concepts**: Familiarity with IP addressing, routing, IPSec, GRE, BGP, VRFs, SD-WAN, and network security.
- **Infrastructure as Code**: Experience with AWS CloudFormation or Terraform.
- **AWS Account**: An AWS account with appropriate IAM permissions to create networking resources.

## Support & Feedback

AWS Cloud WAN Blueprints are maintained by AWS Solution Architects. This is not part of an AWS service and support is provided as best-effort by the Cloud WAN Blueprints community. To provide feedback, please use the [issues templates](https://github.com/aws-samples/aws-cloud-wan-blueprints/issues) provided. If you are interested in contributing to Cloud WAN Blueprints, see the [Contribution guide](CONTRIBUTING.md).

## FAQ

**Q: Why do some patterns show "Coming Soon"?**

A: We're actively developing the blueprint library. We've structured the repository to show the planned patterns while we work on completing them. See [CONTRIBUTING](./CONTRIBUTING.md) to provide feedback or request new patterns.

**Q: Can I use these patterns in production?**

A: These patterns are **not ready** for production environments. They should be customized for your specific requirements. Update variables, CIDR blocks, and configurations before deploying to production. Always test in pre-production environments first.

**Q: What are the bandwidth and MTU limits for Cloud WAN?**

A: Each Core Network Edge (CNE) supports up to 100 Gbps throughput. For detailed quotas and limits, see the [AWS Cloud WAN quotas documentation](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-quotas.html).

**Q: Do I need separate AWS accounts to use these patterns?**

A: No, most patterns can be deployed in a single AWS account. However, the [Multi-AWS Account pattern](./patterns/2-multi_account/) demonstrates cross-account deployment using AWS Resource Access Manager (RAM).

**Q: Which IaC tool should I use?**

A: Both CloudFormation and Terraform are supported for most patterns. Choose based on your organization's preferences and existing tooling. Terraform patterns use the [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) and [AWSCC](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs) providers, while CloudFormation patterns use native AWS resources.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See [LICENSE](LICENSE).
