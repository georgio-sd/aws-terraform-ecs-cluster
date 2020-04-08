# ECS cluster configuration
#
#
# Number of EC2 instances to launch in your ECS cluster
ecsDesiredCapacity = "2"
#
# Number of EC2 instances to launch in your ECS cluster
ecsMaxCapacity = "6"
#
# Image type, spot price and key
ecsInstanceType = "t3a.micro"
ecsInstanceSP   = "0.0116"
ecsInstanceKey  = "Ohio-keys"
#
# VPC and subnets CIDRs, and AZones' list
vpcCidr           = "10.0.0.0/16"
publicSubnetACidr = "10.0.0.0/24"
publicSubnetBCidr = "10.0.1.0/24"
AZoneNames        = ["us-east-2a", "us-east-2b"]
#
# Tag
tagName = "ECS-Cluster"
