# AWS VPC Flow Logs Terraform Module

This Terraform module enables VPC Flow Logs with flexible configuration options for AWS resources such as VPCs, subnets, ENIs, or Transit Gateway Attachments. The flow logs can be stored in CloudWatch, S3, or streamed to Kinesis Data Firehose.

## Features

- Supports multiple AWS resources (VPCs, Subnets, ENIs, Transit Gateways, and Attachments).
- Destination options for logs: CloudWatch, S3, and Kinesis Data Firehose.
- Configurable log format, file format, and aggregation intervals.
- Supports conditional validation for various input variables.
- Provides precondition checks to ensure the resource exists in the AWS account and region.
- Generates tags for resource management and tracking.

## Usage

Below is an example usage of the module:

### Example `main.tf`

```hcl
module "vpc_flow_logs" {
  source = "path-to-this-module"

  aws_region               = "ap-south-1"
  resource_id              = "vpc-0123456789abcdef0"
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  file_format              = "plain-text"
  max_aggregation_interval = 600
  log_format               = "$${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport}"
}
```

### Variable Configuration Example

For advanced configurations, you can define variables in `variable.tf` as follows:

```hcl
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "traffic_type" {
  type = string
  validation {
    condition     = var.traffic_type == "ALL" || var.traffic_type == "ACCEPT" || var.traffic_type == "REJECT"
    error_message = "Value can be either ALL, ACCEPT, or REJECT"
  }
  default = "ALL"
}

variable "log_destination_type" {
  type = string
  validation {
    condition     = var.log_destination_type == "cloud-watch-logs" || var.log_destination_type == "s3" || var.log_destination_type == "kinesis-data-firehose"
    error_message = "Value must be either 'cloud-watch-logs', 's3', or 'kinesis-data-firehose'"
  }
  default = "cloud-watch-logs"
}
```

## Input Variables

| Variable Name                | Type   | Default                 | Description                                                                   |
| ---------------------------- | ------ | ----------------------- | ----------------------------------------------------------------------------- |
| `aws_region`                 | string | `ap-south-1`            | AWS Region where the resources are located.                                   |
| `traffic_type`               | string | `ALL`                   | Type of traffic to capture: `ALL`, `ACCEPT`, or `REJECT`.                     |
| `log_destination_type`       | string | `kinesis-data-firehose` | Destination for logs: `cloud-watch-logs`, `s3`, or `kinesis-data-firehose`.   |
| `file_format`                | string | `plain-text`            | File format for logs: `plain-text` or `parquet`.                              |
| `max_aggregation_interval`   | number | `600`                   | Maximum aggregation interval in seconds. Acceptable values are `60` or `600`. |
| `log_format`                 | string | `$${interface-id} ...`  | Log format with supported placeholders.                                       |
| `resource_id`                | string | -                       | AWS Resource ID (VPC, Subnet, ENI, TGW, or TGW Attachment).                   |
| `deliver_cross_account_role` | string | `null`                  | Optional role ARN for cross-account log delivery.                             |
| `hive_compatible_partitions` | bool   | `false`                 | Enable Hive-compatible partitions for S3 destination.                         |
| `per_hour_partition`         | bool   | `false`                 | Enable per-hour partitioning for S3 destination.                              |

## Resources Created

The module dynamically creates the following resources based on the configuration:

- **CloudWatch Log Group**: Created if `log_destination_type = cloud-watch-logs`.
- **S3 Bucket**: Created if `log_destination_type = s3` or `kinesis-data-firehose`.
- **Kinesis Data Firehose Delivery Stream**: Created if `log_destination_type = kinesis-data-firehose`.
- **IAM Role and Policy**: Created for log delivery if required.
- **VPC Flow Log Resource**: Captures logs for the specified AWS resource.

### Detailed Resource Information

1. **CloudWatch Log Group**:
   - Name: `flow_log_cloud_watch_log_group`
   - Retains logs based on CloudWatch configuration.

2. **S3 Bucket**:
   - Name: `flow-log-bucket-ot-security-module-v1`
   - Used for storing logs if `log_destination_type` is `s3` or `kinesis-data-firehose`.

3. **Kinesis Data Firehose Delivery Stream**:
   - Name: `kinesis_firehose_flow_log_group`
   - Configured for extended S3 delivery.

4. **IAM Role and Policy**:
   - Role Name: `flow_log_role`
   - Grants necessary permissions for CloudWatch, S3, or Kinesis access.

5. **VPC Flow Log Resource**:
   - Captures network traffic logs for VPCs, Subnets, ENIs, TGWs, or TGW Attachments.

## Outputs

| Output Name | Description                          |
| ----------- | ------------------------------------ |
| `log_group` | ARN of the CloudWatch Log Group.     |
| `s3_bucket` | Name of the S3 Bucket for Flow Logs. |
| `firehose`  | Name of the Kinesis Firehose Stream. |

## Notes

- Ensure the resource ID provided is valid and exists in the specified AWS account and region.
- The IAM Role created for log delivery must have the appropriate permissions.
- Use preconditions to verify resource availability before deployment.

## License

This module is distributed under the OpsTree Solutions.

