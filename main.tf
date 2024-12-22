## Dynamic template for the flow logs according to the service the servcie that user want.
 provider "aws" {
   access_key = ""
   secret_key = ""
   region = var.aws_region
 }
## Getting the resource id for which aws vpc flow logs are to be enabled
data "aws_vpc" "flow_log_vpc" {
  count = startswith(var.resource_id,"vpc-")?1:0
  id = var.resource_id
}

data "aws_subnet" "flow_log_subnet" {
  count = startswith(var.resource_id,"subnet-")?1:0
  id = var.resource_id
}

data "aws_network_interface" "flow_log_eni" {
  count = startswith(var.resource_id,"eni-")?1:0
  id = var.resource_id
}

data "aws_ec2_transit_gateway" "flow_log_transit_gateway" {
  count = startswith(var.resource_id,"tgw-")?1:0
  id = var.resource_id
}

data "aws_ec2_transit_gateway_attachment" "flow_log_transit_gateway_attachment" {
 count = startswith(var.resource_id,"tgw-attach-")?1:0
 transit_gateway_attachment_id = var.resource_id
}

## Requirement for creating vpc flow log destination type to cloud watch
resource "aws_cloudwatch_log_group" "flow_log_cloudwatch_log" {
  count = var.log_destination_type == "cloud-watch-logs"?1:0
  name = "flow_log_cloud_watch_log_group"
}

##bucket created for the firehose logging and s3 logging

resource "aws_s3_bucket" "vpc_flow_log_bucket" {
  count = (var.log_destination_type == "s3" || var.log_destination_type == "kinesis-data-firehose")?1:0
  bucket = "flow-log-bucket-ot-security-module-v1"
  
}

/*resource "aws_s3_bucket_acl" "flow_log_bucket_acl" {
  bucket = aws_s3_bucket.vpc_flow_log_bucket[0].id
  acl    = "private"
}*/

## Requirement if flow log destination type set to firehose logging
  resource "aws_kinesis_firehose_delivery_stream" "flow_log_firehose_logging_group" {
  count = var.log_destination_type == "kinesis-data-firehose"?1:0
  name        = "kinesis_firehose_flow_log_group"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.flow_log_role[0].arn
    bucket_arn = aws_s3_bucket.vpc_flow_log_bucket[0].arn
  }

  tags = {
    "LogDeliveryEnabled" = "true"
  }
}

## Role required according to the log destination provided to the aws flow log resource
resource "aws_iam_role" "flow_log_role" {
  count = var.log_destination_type == "s3"?0:1
  name = "flow_log_role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role[0].json
}

resource "aws_iam_role_policy" "flow_log_policy" {
  count = var.log_destination_type == "s3"?0:1
  name   = "flow_log_role"
  role   = aws_iam_role.flow_log_role[0].id
  policy = data.aws_iam_policy_document.flow_log_policy_document[0].json
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
    ]:(var.log_destination_type == "kinesis-data-firehose"?[
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
  eni_id = try(data.aws_network_interface.flow_log_eni[0].id, null)
  subnet_id = try(data.aws_subnet.flow_log_subnet[0].id, null)
  vpc_id = try(data.aws_vpc.flow_log_vpc[0].id, null)
  transit_gateway_id = try(data.aws_ec2_transit_gateway.flow_log_transit_gateway[0].id, null)
  transit_gateway_attachment_id = try(data.aws_ec2_transit_gateway_attachment.flow_log_transit_gateway_attachment[0].id, null)
  iam_role_arn = var.log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log_role[0].arn : null
  log_destination_type = var.log_destination_type
  log_destination = var.log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_log_cloudwatch_log[0].arn:(var.log_destination_type == "kinesis-data-firehose" ? aws_kinesis_firehose_delivery_stream.flow_log_firehose_logging_group[0].arn : aws_s3_bucket.vpc_flow_log_bucket[0].arn)
  log_format = var.log_format
  max_aggregation_interval = var.max_aggregation_interval
  dynamic "destination_options" {
    for_each = var.log_destination_type == "s3" ?[1]:[]
    content {
    file_format = var.file_format
    hive_compatible_partitions = var.hive_compatible_partitions
    per_hour_partition = var.per_hour_partition
    }
  }
  tags = {
    owner = "OT"
    version = "0.0.1"
  }
  lifecycle {
    precondition {
      condition = data.aws_vpc.flow_log_vpc !=null || data.aws_subnet.flow_log_subnet !=null || data.aws_ec2_transit_gateway.flow_log_transit_gateway !=null || data.aws_network_interface.flow_log_eni !=null || data.aws_ec2_transit_gateway_attachment.flow_log_transit_gateway_attachment !=null
      error_message = " The resource is not found in the account. Verify account and region."
    }
  }
  depends_on = [ aws_iam_role.flow_log_role, data.aws_subnet.flow_log_subnet ]
}

