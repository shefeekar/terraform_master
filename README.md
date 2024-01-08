**AWS Infrastructure with Multi-AZ Web Servers**

**Description:**
This Terraform code provisions a robust AWS infrastructure for hosting web servers in a multi-Availability Zone (AZ) environment.
It sets up the fundamental components, including a Virtual Private Cloud (VPC), Internet Gateway, Route Table, Subnet, Security Group, Network Interface, Elastic IP, 
and multiple EC2 instances. The infrastructure is designed for high availability and security, with a focus on simplicity and scalability.

1. **Terraform Configuration:** Specifies required providers.
2. **AWS Provider Configuration:** Configures AWS settings like region, credentials, and endpoints.
3. **VPC Creation:** Establishes a VPC with a specific CIDR block.
4. **Internet Gateway:** Creates an Internet Gateway and associates it with the VPC.
5. **Route Table:** Defines a route table with default routes for IPv4 and IPv6.
6. **Subnet Creation:** Establishes a subnet within the VPC for resource isolation.
7. **Route Table Association:** Associates the subnet with the route table.
8. **Security Group:** Defines a security group allowing specific inbound and all outbound traffic.
9. **Network Interface:** Creates a network interface within the subnet with a specified private IP and associated security group.
10. **Elastic IP:** Allocates an Elastic IP and associates it with the network interface.
11. **EC2 Instances:** Deploys multiple EC2 instances with a specified AMI, instance type, and user data for Apache installation and a basic web page.

# Terraform AWS Infrastructure

This Terraform script sets up a basic AWS infrastructure for a web application. 
The infrastructure includes a VPC, Internet Gateway, Route Table, Subnet, Security Group, Network Interface, Elastic IP, and multiple EC2 instances running Apache web servers.

## Prerequisites

Before running this Terraform script, ensure you have the following:

1. AWS account credentials with the necessary permissions.
2. Terraform installed on your local machine.

## Usage

1. Clone the repository:
    
    ```bash
    git clone https://github.com/shefeekar/terraform_master.git
    cd terraform_master
    
    ```
    
2. Open the `main.tf` file and update the AWS access and secret keys.
3. Initialize the Terraform configuration:
    
    ```bash
    terraform init
    
    ```
    
4. Apply the Terraform configuration:
    
    ```bash
    terraform apply
    
    ```
    
    Enter `yes` when prompted to confirm the changes.
    
5. Once the infrastructure is created, you can access the web servers at the Elastic IP addresses associated with the instances.
6. To destroy the infrastructure when done, run:
    
    ```bash
    terraform destroy
    
    ```
    
    Enter `yes` when prompted to confirm the destruction.
    

## Infrastructure Details

Certainly! Let's break down the two blocks you provided:

### **Terraform Configuration**

```
hclCopy code
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

```

- **Explanation:** This block specifies the required Terraform providers for the configuration. In this case, it states that the configuration relies on the **`aws`** provider, and the source for this provider is the official HashiCorp registry (**`hashicorp/aws`**).

### **AWS Provider Configuration**

provider "aws" {
region                      = "us-east-1"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
access_key                  = var.access_key
secret_key                  = var.secret_key

endpoints {
ec2 = "[http://localhost:4566](http://localhost:4566/)"
}
}

- **`region`**: Specifies the AWS region to be used, which is set to "us-east-1" in this case.
- **`skip_credentials_validation`**: When set to **`true`**, this skips the validation of AWS credentials. Useful in scenarios like local development where credentials may not be required or need to be explicitly skipped.
- **`skip_metadata_api_check`**: Setting this to **`true`** skips checking the AWS metadata API. This can be handy in environments where access to the metadata API is not necessary.
- **`skip_requesting_account_id`**: When set to **`true`**, Terraform skips requesting the AWS account ID. This can be useful in situations where retrieving the account ID is not required.
- **`access_key`** and **`secret_key`**: These are variables (**`var.access_key`** and **`var.secret_key`**) containing the AWS access and secret keys used for authentication. This allows for more dynamic configurations by pulling in values from external sources.
- **`endpoints`**: Configures specific endpoints for AWS services. In this case, it sets the EC2 endpoint to "[http://localhost:4566](http://localhost:4566/)". This is commonly used in local development environments where tools like LocalStack simulate AWS services locally.

### VPC

- **CIDR Block:** 10.0.0.0/16
- **Name Tag:** production

resource "aws_vpc" "prod-vpc" {
cidr_block = "10.0.0.0/16"
tags = {
"Name" = "production"
}
}

The VPC (Virtual Private Cloud) defines the private network environment. It uses the CIDR block 10.0.0.0/16 and has a name tag "production".

### Internet Gateway

resource "aws_internet_gateway" "gw" {
vpc_id = aws_vpc.prod-vpc.id
}

The Internet Gateway is attached to the VPC, enabling communication between the VPC and the Internet.

### Route Table

resource "aws_route_table" "prod-route-table" {
vpc_id = aws_vpc.prod-vpc.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gw.id
}

route {
ipv6_cidr_block = "::/0"
gateway_id = aws_internet_gateway.gw.id
}

tags = {
Name = "production"
}
}

The Route Table specifies how traffic should be directed within the VPC. It has routes for both IPv4 and IPv6 to the Internet Gateway.

### Subnet

resource "aws_subnet" "subnet-1" {
vpc_id = aws_vpc.prod-vpc.id
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"

tags = {
Name = "production subnet"
}
}

The Subnet is a range of IP addresses in the VPC. It uses the CIDR block 10.0.1.0/24, is located in availability zone "us-east-1a", and has a name tag "production subnet".

### Security Group (allow_web)

resource "aws_security_group" "allow_web" {
name = "allow_web"
description = "Allow TLS inbound traffic"
vpc_id = aws_vpc.prod-vpc.id

ingress {
description = "HTTPS"
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
description = "HTTP"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
description = "SSH"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {
Name = "allow-web"
}
}

The Security Group named "allow_web" controls inbound and outbound traffic for the instances. It allows incoming traffic on ports 80, 443, and 22.

### Network Interface

resource "aws_network_interface" "web-server-nic" {
subnet_id = aws_subnet.subnet-1.id
private_ips = ["10.0.1.50"]
security_groups = [aws_security_group.allow_web.id]
}

The Network Interface is attached to the specified subnet, has a private IP address (10.0.1.50), and is associated with the "allow_web" security group.

### Elastic IP

resource "aws_eip" "one" {
domain = "vpc"

network_interface = aws_network_interface.web-server-nic.id
associate_with_private_ip = "10.0.1.50"
depends_on = [ aws_internet_gateway.gw ]
}

The Elastic IP is associated with the Network Interface and ensures a static IP address for the instances. It depends on the Internet Gateway for proper functioning.

### EC2 Instances

resource "aws_instance" "web-server-instance" {
ami = "ami-0c7217cdde317cfec"
instance_type = "t2.micro"
key_name = "terraform-project"
availability_zone = "us-east-1a"
count = 3
network_interface {
device_index = 0
network_interface_id = aws_network_interface.web-server-nic.id
}
user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo bash -c 'echo "look at me im here." > /var/www/html/index.html'
EOF
}

This block creates three EC2 instances with the specified AMI, instance type, key pair, and user data. The user data installs Apache web server and creates a simple index.html file.

## Notes

- The script deploys three EC2 instances for redundancy and load distribution.
- Customize the script according to your specific requirements.
