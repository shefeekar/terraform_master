terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_requesting_account_id = true
  access_key = var.access_key
  secret_key = var.secret_key
  
  endpoints {
    ec2 = "http://localhost:4566"
    
    
   

  }

}

#Create a vpc
resource "aws_vpc" "prod-vpc" {
     cidr_block = "10.0.0.0/16"
     tags = {
        "Name" = "production"
         }
}
# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  
}
# Create a route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "production"
  }
}
#4 Create A subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "production subnet"
  }
}
#associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
#Create a security group for allowing Port 80,443,22

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
   ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow-web"
  }
}
# Create a network interface with ip in the subnet that was created in the step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]


}
#Assign an elastic ip to the network interface created in step 7
resource "aws_eip" "one" {
  domain                    = "vpc"               
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [ aws_internet_gateway.gw ]
}

#Create ubuntu server and install webserver apache 2 
resource "aws_instance" "web-server-instance" {
  ami           = "ami-0c7217cdde317cfec"# Amazon Linux 2 AMI ID (you can choose a different one)
  instance_type = "t2.micro"             # Change this to your desired instance type
  key_name      = "terraform-project"    # Change this to your key pair name for SSH access
  availability_zone = "us-east-1a"
  count = 1
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



