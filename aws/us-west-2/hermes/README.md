# Hermes Environments 

This Module Directory creates the following resources per environment:

- [Hermes Instance Security Group](env-name/instance-sg/values.yml) 
- [Hermes S3 Bucket for ALB Logs](env-name/s3/values.yml) 
- [Hermes ALB Security Group](env-name/lb/sg/terragrunt.hcl) 
- [Hermes ALB](env-name/lb/alb/terragrunt.hcl) 
- [Hermes ALB Target Group Attachments](env-name/lb/target-groups/terragrunt.hcl)
- [Hermes RDS Cluster](env-name/rds/values.yml) 
- [Hermes AWS Network Interface](env-name/eni/terragrunt.hcl)
- [Hermes EC2 Instance](env-name/instance/terragrunt.hcl)
 
## Requirements

- `vpc_common_vars.yaml` in the root of the vpc folder ex. `prod/vpc_common_vars.yaml`
```yaml
region: us-east-1
# This is used by the env-name module to get all the metadata we need to know about the VPC to
# create the application stack
vpc_name: Bridge-Prod

# The env-module can pull route 53 domain information and return as output
# route53_zones map
bridge_domains:
  - bcrstage.us
  - bcrprod.us

# Returns a map of bucket objects from env-name
buckets:
  - bcr-automation-secrets.terraform/mirth-dev
```
- `env_common.yaml` in the environment folder for hermes

## Creating a new hermes environment in a VPC

- Copy `terragrunt/app-module-templates/hermes` directory to your VPC folder
- Rename the `env-name` folder to your environment name ex. `bcbs-stg`
- Modify the `env_common.yaml` file  to update the variables appropriately
- Edit variables in `env-name/vars` for the various modules
- Make sure to edit the `eni.yaml` and assign a static IP.
- Run `terragrunt plan-all` 
- Resolve any potential issues
- Run `terragrunt apply-all`

*NOTE* All module variables are now located in the vars folder.

## Importing existing resources 
- Edit [Variables](env-name/vars) and/or `terragrunt.hcl` files for the module resource you would like to import
- Remove any dependencies that define variables that are no longer needed
- `terragrunt plan` and resolve issues
- Run the import of the resource
- Run `terragrunt plan` and check for discrepancies. Resolve discrepancies by referencing the resource source module to set any needed variables.

## Pointing a target group to a different instance outside the environment

```hcl
resource "aws_alb_target_group_attachment" "this" {
  for_each = var.target_groups
  target_group_arn = aws_lb_target_group.this[each.key].arn
  target_id = lookup(each.value, "instance_id", var.instance_id)
}
```

To change the target for a target group add the key `instance_id` to the map for the path. 

```yaml
  stg-Wellspan-Livongo-Epic:
    path_pattern: "/LIVONGO-SSO/saml"
    backend_port: "9035"
    backend_protocol: "HTTP"
    health_check_interval: 300
```

```yaml
  stg-Wellspan-Livongo-Epic:
    path_pattern: "/LIVONGO-SSO/saml"
    backend_port: "9035"
    backend_protocol: "HTTP"
    health_check_interval: 300
    instance_id: "i-0b7ed20886fe56d0e"
```