
variable "awsAccessKey" {}
variable "awsSecretKey" {}
variable "awsRegion" {}

variable "ServiceName" {
  type    = string
  default = "nginx13"
}
variable "ImageName" {
  type    = string
  default = "nginx"
}
variable "MountPoint" {
  type    = string
  default = "/usr/share/nginx/html"
}
variable "ContainerMemory" {
  type    = number
  default = 256
}
variable "DesiredCount" {
  type    = number
  default = 2
}
variable "PortNumber" {
  type    = number
  default = 80
}

provider "aws" {
  access_key = var.awsAccessKey
  secret_key = var.awsSecretKey
  region     = var.awsRegion
}
data "terraform_remote_state" "Cluster" {
  backend = "local"
  config = {
    path = "../../Cluster/terraform.tfstate"
  }
}

resource "aws_ecs_task_definition" "Task" {
  family = var.ServiceName
  # container_definitions = file("service.json")
  container_definitions = templatefile("service.json", { name = var.ServiceName, image = var.ImageName,
  memory = var.ContainerMemory, containerPath = var.MountPoint, containerPort = var.PortNumber })
  tags = {
    Name    = data.terraform_remote_state.Cluster.outputs.TagName
    Project = data.terraform_remote_state.Cluster.outputs.TagName
  }
  volume {
    name = "service-storage"
    efs_volume_configuration {
      file_system_id = data.terraform_remote_state.Cluster.outputs.EfsVolumeId
      root_directory = "/"
    }
  }
}
resource "aws_ecs_service" "Service" {
  name            = var.ServiceName
  cluster         = data.terraform_remote_state.Cluster.outputs.EcsClusterId
  task_definition = aws_ecs_task_definition.Task.arn
  desired_count   = var.DesiredCount
  load_balancer {
    target_group_arn = data.terraform_remote_state.Cluster.outputs.AlbTargetGroupArn
    container_name   = var.ServiceName
    container_port   = var.PortNumber
  }
}
