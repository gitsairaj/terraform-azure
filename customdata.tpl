#!/bin/bash

# Update the system
sudo yum update -y

# Install required packages
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Configure Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the 'docker' group
sudo usermod -aG docker testuser

# Enable Docker to start on system boot
sudo systemctl enable docker

# Print Docker version
#docker version