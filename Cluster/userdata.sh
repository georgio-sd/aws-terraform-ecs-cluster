#!/bin/bash -xe
echo ECS_CLUSTER=${ecscluster} >> /etc/ecs/ecs.config
yum install -y amazon-efs-utils mc
mkdir /mnt/efs
echo -e "${efsid}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
yum update -y
reboot
