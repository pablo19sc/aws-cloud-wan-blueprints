# AWS Cloud WAN multi-AWS Account environment (Terraform)

![Multi-Account Architecture](../../../images/patterns_multi_account.png)

## Prerequisites
- Two AWS accounts with an IAM user with the appropriate permissions

## Usage

### Deployment
- Clone the repository and move to the folder

```bash
git clone https://github.com/aws-samples/aws-cloud-wan-blueprints.git
cd patterns/2-multi_account/terraform
```

- Assume credentials for the *Networking AWS Account* and move to the *networking* folder. Configure a value for the variable `spoke_account` - we recommend the use of a [tfvars](https://developer.hashicorp.com/terraform/language/values/variables) file.
    - Take note of the `resource_share_arn` output.

```bash
cd networking/
terraform apply
```

- Assume credentials for the *Spoke AWS Account* and move to the *spoke* folder.
    - (Optional) Edit the variables.tf file in the project root directory - if you want to test with different parameters.
    - Configure a value for the variable `resource_share_arn` - we recommend the use of a [tfvars](https://developer.hashicorp.com/terraform/language/values/variables) file.

```bash
cd ../spoke/
terraform apply
```

**Note** EC2 instances will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

### Clean-up
- Assume credentials for the *Spoke AWS Account* and move to the *spoke* folder.

```bash
cd spoke/
terraform destroy
```

- Assume credentials for the *Networking AWS Account* and move to the *networking* folder.

```bash
cd ../networking/
terraform destroy
```
