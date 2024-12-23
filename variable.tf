variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS Region where the resources are located."
}

variable "traffic_type" {
  type        = string
  default     = "ALL"
  description = "Type of traffic to capture: ALL, ACCEPT, or REJECT."
  validation {
    condition     = var.traffic_type == "ALL" || var.traffic_type == "ACCEPT" || var.traffic_type == "REJECT"
    error_message = "Value can be either ALL, ACCEPT, or REJECT."
  }
}

variable "log_destination_type" {
  type        = string
  default     = "kinesis-data-firehose"
  description = "Destination for logs: cloud-watch-logs, s3, or kinesis-data-firehose."
  validation {
    condition     = var.log_destination_type == "cloud-watch-logs" || var.log_destination_type == "s3" || var.log_destination_type == "kinesis-data-firehose"
    error_message = "Value must be either 'cloud-watch-logs', 's3', or 'kinesis-data-firehose'."
  }
}

variable "file_format" {
  type        = string
  default     = "plain-text"
  description = "File format for logs: plain-text or parquet."
  validation {
    condition     = var.file_format == "plain-text" || var.file_format == "parquet"
    error_message = "Values can be either 'plain-text' or 'parquet' format."
  }
}

variable "max_aggregation_interval" {
  type        = number
  default     = 600
  description = "Maximum aggregation interval in seconds: 60 or 600."
  validation {
    condition     = var.max_aggregation_interval == 60 || var.max_aggregation_interval == 600
    error_message = "Value should be either 60 seconds or 600 seconds."
  }
}

variable "log_format" {
  type        = string
  default     = "$${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport}"
  description = "Log format with supported placeholders."
}

variable "resource_id" {
  type        = string
  description = "AWS Resource ID (e.g., VPC, Subnet, ENI, TGW, or TGW Attachment)."
  validation {
    condition     = var.resource_id != null
    error_message = "Resource ID cannot be null."
  }
}

variable "deliver_cross_account_role" {
  type        = string
  default     = null
  description = "Optional role ARN for cross-account log delivery."
}

variable "hive_compatible_partitions" {
  type        = bool
  default     = false
  description = "Enable Hive-compatible partitions for S3 destination."
}

variable "per_hour_partition" {
  type        = bool
  default     = false
  description = "Enable per-hour partitioning for S3 destination."
}

variable "aws_terraform_role" {
  type        = string
  description = "ARN of the AWS role to assume for Terraform operations."
  validation {
    condition     = startswith(var.aws_terraform_role, "arn")
    error_message = "Must be a valid AWS role ARN."
  }
}

variable "terraform_session" {
  type        = string
  description = "Session name for Terraform AWS provider."
}
