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
* Task nginx (presented as an example)
* All new resources are taged and/or named to let us know that they belong to this project

(!) You need to check the number of spot instances limit in your account. By default, this number is zero and you need to request a limit increase.

![VPC-Image](https://github.com/georgio-sd/aws-terraform-ecs-cluster/raw/master/aws2.jpg)

Instruction (for windows users):
1. Edit config.tfvars and credentials.tfvar

2. Run commands<br>
cd Cluster<br>
terraform init<br>
cluster-plan.bat<br>
cluster-apply.bat<br>
cd ..\Tasks\nginx<br>
terraform init<br>
task-plan.bat<br>
task-apply.bat<br>

3. Open ALB URL in an Internet Brouser and you will get access to two nginx containers through the Load Balancer.
