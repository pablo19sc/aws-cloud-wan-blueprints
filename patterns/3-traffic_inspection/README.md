# AWS Cloud WAN Blueprints - Traffic Inspection architectures

Within this section of the blueprints, we are providing several examples on how you can include firewalls in the Cloud WAN traffic. There are several use cases covered:

- [Centralized Outbound (send-to)](./1-centralized_outbound/)
- [East-West (send-via)](./2-east_west/)
- [Outbound (send-to) & east-west (send-via dual-hop)](./3-outbound_east_west_dualhop/)
- [Outbound (send-to) & east-west (send-via single-hop)](./4-outbound_east_west_singlehop/)
- [Outbound & east-west (VPCs attached to Transit Gateway)](./5-spoke_vpcs_tgw/)

In all use cases, you will find two routing domains: **production** and **development**. The inspection requirements are the following ones:

* VPC traffic within the **production** segment will be inspected.
* Inter-segment traffic will be inspected.
* VPCs within the **development** segment can talk between each other directly.

This repository does not focus on [AWS Network Firewall](https://aws.amazon.com/network-firewall/)'s policy configuration, therefore the policy rules configured are simple and only used to test connectivity.

* For egress traffic, only traffic to *.amazon.com* domains is allowed.
* For east-west traffic, any ICMP packets are alerted and allowed.
