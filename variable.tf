variable "aws_region" {
  type = string
  default = "ap-south-1"
}

variable "traffic_type" {
  type = string
  validation {
    condition = var.traffic_type == "ALL" || var.traffic_type =="ACCEPT" || var.traffic_type == "REJECT"
    error_message = " Value can be either ALL, ACCEPT or REJECT "
  }
  default = "ALL"
}

variable "log_destination_type" {
    type = string
    validation {
      condition = var.log_destination_type == "cloud-watch-logs" || var.log_destination_type == "s3" || var.log_destination_type == "kinesis-data-firehose"
      error_message = "value must be either 'cloud-watch-logs', 's3', 'kinesis-data-firehose' "
    }

    default = "kinesis-data-firehose"
}

variable "file_format" {
  type = string
  default = "plain-text"
  validation {
  condition = var.file_format == "plain-text" || var.file_format == "parquet"
  error_message = "Values can be eiter 'plain-text' or 'parquet' format"
  }
}

variable "max_aggregation_interval" {
  type = number
  default = 600
  validation {
    condition = var.max_aggregation_interval == 60 || var.max_aggregation_interval == 600
    error_message = "Value should be either 60 seconds or 600 seconds"
  }
}

## need to make default change accoring to the transit gateway id and attachment
variable "log_format" {
  type = string
  default = "$${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport}"
}

variable "resource_id" {
    type = string
    validation {
      condition = var.resource_id != null
      error_message = "Resource Id cannot be rule"
    }
}

variable "deliver_cross_account_role" {
  default = null
  
}

variable "hive_compatible_partitions" {
  type = bool
  default = false
}

variable "per_hour_partition" {
  type = bool
  default = false
}