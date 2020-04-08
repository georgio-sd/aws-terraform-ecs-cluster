variable "awsAccessKey" {}
variable "awsSecretKey" {}
variable "awsRegion" {}
variable "ecsDesiredCapacity" {}
variable "ecsMaxCapacity" {}
variable "ecsInstanceType" {}
variable "ecsInstanceSP" {}
variable "ecsInstanceKey" {}
variable "vpcCidr" {}
variable "publicSubnetACidr" {}
variable "publicSubnetBCidr" {}
variable "AZoneNames" {}
variable "tagName" {}

provider "aws" {
  access_key = var.awsAccessKey
  secret_key = var.awsSecretKey
  region     = var.awsRegion
}

# VPC, IGW and Subnets
resource "aws_vpc" "EcsVPC" {
  cidr_block           = var.vpcCidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_internet_gateway" "EcsInternetGateway" {
  vpc_id = aws_vpc.EcsVPC.id
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_subnet" "PublicSubnetA" {
  vpc_id                  = aws_vpc.EcsVPC.id
  cidr_block              = var.publicSubnetACidr
  availability_zone       = var.AZoneNames[0]
  map_public_ip_on_launch = true
  tags = {
    Name    = "PublicSubnetA"
    Project = var.tagName
  }
}
resource "aws_subnet" "PublicSubnetB" {
  vpc_id                  = aws_vpc.EcsVPC.id
  cidr_block              = var.publicSubnetBCidr
  availability_zone       = var.AZoneNames[1]
  map_public_ip_on_launch = true
  tags = {
    Name    = "PublicSubnetB"
    Project = var.tagName
  }
}
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.EcsVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.EcsInternetGateway.id
  }
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_route_table_association" "PublicSubnetARouteTableAssociation" {
  subnet_id      = aws_subnet.PublicSubnetA.id
  route_table_id = aws_route_table.PublicRouteTable.id
}
resource "aws_route_table_association" "PublicSubnetBRouteTableAssociation" {
  subnet_id      = aws_subnet.PublicSubnetB.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

# ASG and ECSInstance Roles
data "aws_iam_policy_document" "AutoscalingRolePolicy" {
  statement {
    effect = "Allow"
    actions = ["application-autoscaling:*", "cloudwatch:DescribeAlarms", "cloudwatch:PutMetricAlarm",
    "ecs:DescribeServices", "ecs:UpdateService"]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "AutoscalingAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "AutoscalingPolicy" {
  name   = "AutoscalingPolicy"
  policy = data.aws_iam_policy_document.AutoscalingRolePolicy.json
}
resource "aws_iam_role" "AutoscalingRole" {
  name               = "AutoscalingRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.AutoscalingAssumeRolePolicy.json
}
resource "aws_iam_role_policy_attachment" "AutoscalingRolePolicyAttachment" {
  role       = aws_iam_role.AutoscalingRole.name
  policy_arn = aws_iam_policy.AutoscalingPolicy.arn
}
data "aws_iam_policy_document" "InstanceRolePolicy" {
  statement {
    effect = "Allow"
    actions = ["ecs:CreateCluster", "ecs:DeregisterContainerInstance", "ecs:DiscoverPollEndpoint",
      "ecs:Poll", "ecs:RegisterContainerInstance", "ecs:StartTelemetrySession", "ecs:Submit*",
      "logs:CreateLogStream", "logs:PutLogEvents", "ecr:GetAuthorizationToken", "ecr:BatchGetImage",
    "ecr:GetDownloadUrlForLayer"]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "InstanceAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "InstancePolicy" {
  name   = "InstancePolicy"
  policy = data.aws_iam_policy_document.InstanceRolePolicy.json
}
resource "aws_iam_role" "InstanceRole" {
  name               = "InstanceRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.InstanceAssumeRolePolicy.json
}
resource "aws_iam_role_policy_attachment" "InstanceRolePolicyAttachment" {
  role       = aws_iam_role.InstanceRole.name
  policy_arn = aws_iam_policy.InstancePolicy.arn
}

# ECS Cluster, ASG and SGs
resource "aws_ecs_cluster" "EcsCluster" {
  name = var.tagName
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_security_group" "EcsInstanceSG" {
  name        = "EcsInstanceSG"
  description = "Allow all traffic from ALB"
  vpc_id      = aws_vpc.EcsVPC.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "EcsInstanceSG"
    Project = var.tagName
  }
}
resource "aws_security_group_rule" "EcsInstanceSGIngressFromALB" {
  description              = "Ingress from the ALB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.EcsInstanceSG.id
  source_security_group_id = aws_security_group.LoadBalancerSG.id
}
resource "aws_security_group_rule" "EcsInstanceSGIngressFromSelf" {
  description              = "Ingress from other hosts with the same security group"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.EcsInstanceSG.id
  source_security_group_id = aws_security_group.EcsInstanceSG.id
}
resource "aws_autoscaling_group" "EcsAutoScalingGroup" {
  name                 = "EcsAutoScalingGroup"
  min_size             = 1
  max_size             = var.ecsMaxCapacity
  desired_capacity     = var.ecsDesiredCapacity
  launch_configuration = aws_launch_configuration.EcsLaunchConfig.name
  vpc_zone_identifier  = [aws_subnet.PublicSubnetA.id, aws_subnet.PublicSubnetB.id]
  tag {
    key                 = "Name"
    value               = var.tagName
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = var.tagName
    propagate_at_launch = true
  }
}
data "aws_ami" "EcsLatestAmi" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
resource "aws_launch_configuration" "EcsLaunchConfig" {
  image_id             = data.aws_ami.EcsLatestAmi.id
  instance_type        = var.ecsInstanceType
  key_name             = var.ecsInstanceKey
  spot_price           = var.ecsInstanceSP
  security_groups      = [aws_security_group.EcsInstanceSG.id]
  iam_instance_profile = aws_iam_instance_profile.EcsInstanceProfile.name
  user_data            = templatefile("userdata.sh", { efsid = aws_efs_file_system.EfsVolume.id, ecscluster = var.tagName })
  depends_on           = [aws_efs_mount_target.EfsVolumeMountTargetA, aws_efs_mount_target.EfsVolumeMountTargetB]
}
resource "aws_iam_instance_profile" "EcsInstanceProfile" {
  name = "EcsInstanceProfile"
  role = aws_iam_role.InstanceRole.name
}

# EFS and EfsSG
resource "aws_security_group" "EfsSG" {
  name        = "EfsSG"
  description = "Allow NFS traffic"
  vpc_id      = aws_vpc.EcsVPC.id
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpcCidr]
  }
  tags = {
    Name    = "EfsSG"
    Project = var.tagName
  }
}
resource "aws_efs_file_system" "EfsVolume" {
  creation_token = "EfsVolume"
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_efs_mount_target" "EfsVolumeMountTargetA" {
  file_system_id  = aws_efs_file_system.EfsVolume.id
  subnet_id       = aws_subnet.PublicSubnetA.id
  security_groups = [aws_security_group.EfsSG.id]
}
resource "aws_efs_mount_target" "EfsVolumeMountTargetB" {
  file_system_id  = aws_efs_file_system.EfsVolume.id
  subnet_id       = aws_subnet.PublicSubnetB.id
  security_groups = [aws_security_group.EfsSG.id]
}

# ALB and AlbSG
resource "aws_security_group" "LoadBalancerSG" {
  name        = "LoadBalancerSG"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.EcsVPC.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "LoadBalancerSG"
    Project = var.tagName
  }
}
resource "aws_lb" "EcsLoadBalancer" {
  name               = "EscLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LoadBalancerSG.id]
  subnets            = [aws_subnet.PublicSubnetA.id, aws_subnet.PublicSubnetB.id]
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_lb_target_group" "AlbTargetGroup" {
  name     = "AlbTargetGroup"
  port     = 80
  protocol = "HTTP"
  #  target_type = "ip"
  vpc_id = aws_vpc.EcsVPC.id
  tags = {
    Name    = var.tagName
    Project = var.tagName
  }
}
resource "aws_lb_listener" "AlbListener" {
  load_balancer_arn = aws_lb.EcsLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.AlbTargetGroup.arn
  }
}

# Output variables
output "EcsClusterId" {
  description = "Ecs Cluster ID"
  value       = aws_ecs_cluster.EcsCluster.id
}
output "AlbTargetGroupArn" {
  description = "Alb Target Group Arn"
  value       = aws_lb_target_group.AlbTargetGroup.arn
}
output "EfsVolumeId" {
  description = "EFS Volume ID"
  value       = aws_efs_file_system.EfsVolume.id
}
output "TagName" {
  description = "Tag Name"
  value       = var.tagName
}
