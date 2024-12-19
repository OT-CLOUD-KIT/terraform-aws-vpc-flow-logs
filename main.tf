## Dynamic template for the flow logs according to the service the servcie that user want.
 provider "aws" {
   access_key = ""
   secret_key = ""
   region = var.aws_region
 }
## Getting the resource id for which aws vpc flow logs are to be enabled
data "aws_vpc" "flow_log_vpc" {
 id = var.resource_id
}

data "aws_subnet" "flow_log_subnet" {
 id = var.resource_id
}

data "aws_network_interface" "flow_log_eni" {
 id = var.resource_id
}

data "aws_ec2_transit_gateway" "flow_log_transit_gateway" {
 id = var.resource_id
}

data "aws_ec2_transit_gateway_attachment" "flow_log_transit_gateway_attachment" {
 id = var.resource_id
}

## Requirement for creating vpc flow log destination type to cloud watch
resource "aws_cloudwatch_log_group" "flow_log_cloudwatch_log" {
  count = var.log_destination_type == "cloud-watch-logs"?1:0
  name = "flow_log_cloud_watch_log_group"
}

##bucket created for the firehose logging and s3 logging

resource "aws_s3_bucket" "vpc_flow_log_bucket" {
  count = (var.log_destination_type == "s3" || var.log_destination_type == "kinesis-data-firhose")?0:1
  bucket = "flow_log_bucket_ot_security_module_v1"
}

resource "aws_s3_bucket_acl" "flow_log_bucket_acl" {
  bucket = aws_s3_bucket.flow_log_bucket_ot_security_module_v1.id
  acl    = "private"
}

## Requirement if flow log destination type set to firehose logging
  resource "aws_kinesis_firehose_delivery_stream" "flow_log_firehose_logging_group" {
  count = var.log_destination_type == "kinesis-data-firhose"?1:0
  name        = "kinesis_firehose_flow_log_group"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.flow_log_role.arn
    bucket_arn = aws_s3_bucket.flow_log_bucket_ot_security_module_v1.arn
  }

  tags = {
    "LogDeliveryEnabled" = "true"
  }
}

## Role required according to the log destination provided to the aws flow log resource
resource "aws_iam_role" "flow_log_role" {
  count = var.log_destination_type == "s3"?0:1
  name = "flow_log_role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json
}

resource "aws_iam_role_policy" "flow_log_policy" {
  count = var.log_destination_type == "s3"?0:1
  name   = "flow_log_role"
  role   = aws_iam_role.flow_log_role.id
  policy = data.aws_iam_policy_document.flow_log_policy_document.json
}

data "aws_iam_policy_document" "flow_log_assume_role" {
  count = var.log_destination_type == "s3"?0:1
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = var.log_destination_type == "cloud-watch-logs"?["vpc-flow-logs.amazonaws.com"]:["firehose.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "flow_log_policy_document" {
  count = var.log_destination_type == "s3"?0:1
  statement {
    effect = "Allow"

    actions = var.log_destination_type == "cloud-watch-logs"?[
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]:(var.log_destination_type == "kinesis-data-firhose"?[
      "logs:CreateLogDelivery",
    "logs:DeleteLogDelivery",
    "logs:ListLogDeliveries",
    "logs:GetLogDelivery",
    "firehose:TagDeliveryStream",
    ]:null)

    resources = ["*"]
  }
}


## Flow log resource 
resource "aws_flow_log" "flowLog" {
  traffic_type = var.traffic_type
  deliver_cross_account_role = var.deliver_cross_account_role
  eni_id = data.aws_network_interface.flow_log_eni.id
  subnet_id = data.aws_subnet.flow_log_subnet.id
  vpc_id = data.aws_vpc.flow_log_vpc.id
  transit_gateway_id = data.aws_ec2_transit_gateway.flow_log_transit_gateway
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_attachment.flow_log_transit_gateway_attachment
  iam_role_arn = aws_iam_role.flow_log_role.arn
  log_destination_type = var.log_destination_type
  log_destination = var.log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_log_cloudwatch_log.id:(var.log_destination_type == "kinesis-data-firhose" ? aws_kinesis_firehose_delivery_stream.flow_log_firehose_logging_group.id : aws_s3_bucket.vpc_flow_log_bucket.id)
  log_format = var.log_format
  max_aggregation_interval = var.max_aggregation_interval

  destination_options {
    file_format = var.file_format
    hive_compatible_partitions = var.hive_compatible_partitions
    per_hour_partition = var.per_hour_partition
  }
  tags = locals.tags
  lifecycle {
    precondition {
      condition = data.aws_network_interface.flow_log_eni.id != null || data.aws_subnet.flow_log_subnet != null || data.aws_vpc.flow_log_vpc.id != null || data.aws_ec2_transit_gateway_attachment.flow_log_transit_gateway_attachment.id != null || data.aws_ec2_transit_gateway.flow_log_transit_gateway.id != null
      error_message = " The resource is not found in the account. Verify account and region."
    }
  }
  depends_on = [ aws_iam_role.flow_log_role ]
}