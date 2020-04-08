# AWS Terraform ECS Cluster based on EC2 spot instances, Application Load Balancer and Elastic File System
AWS Elastic Container Service on a budget

* New VPC (10.0.0.0/16)
* Internet Gateway for Internet access
* 2 Subnets in 2 Availability Zones A and B<br>
  Public Subnets A (10.0.0.0/24) and B (10.0.1.0/24) with Public IPs<br>
* ECS Cluster based on EC2 spot instances with Auto Scaling Group for Hight Availability<br>
  EC2 instances have Security Groups which allow conncetions only from Load Balancer<br>
* Application Load Balancer with container health monitoring system
* Elastic File System for statefull containers
* All new resources are taged and/or named to let us know that they belong to this project

(!) If you want to use a spot instance for the Bastion host, you need to check the number of spot instance limit in your account. By default, this number is zero and you need to request a limit increase.

![VPC-Image](https://github.com/georgio-sd/aws-terraform-ecs-cluster/raw/master/aws2.jpg)

Instruction (for windows users):
1. Edit config.tfvars and credentials.tfvar

2. Run commands
cd Cluster
terraform init
cluster-plan.bat
cluster-apply.bat
cd ..\Tasks\nginx
terraform init
task-plan.bat
task-apply.bat
